import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type BfVm {
  BfVm(
    code: String,
    cycle: Int,
    pc: Int,
    ptr: Int,
    stdin: String,
    stdout: String,
    mem: List(Int),
  )
}

pub fn to_string(vm: BfVm) -> String {
  let BfVm(code, cycle, pc, ptr, stdin, stdout, mem) = vm
  let cmd = string.slice(code, pc, 1)
  let cmd_str = string.append("cmd: ", cmd)
  let cycle_str = string.append("cycle: ", int.to_string(cycle))
  let pc_str = string.append("pc: ", int.to_string(pc))
  let ptr_str = string.append("ptr: ", int.to_string(ptr))

  let ptr_value_str = case list.first(list.drop(mem, ptr)) {
    Ok(ptr_value) -> string.append("ptr_value: ", int.to_string(ptr_value))
    Error(_) -> string.append("ptr_value: ", "0")
  }
  let stdin_str = string.append("stdin: ", stdin)
  let stdout_str = string.append("stdout: ", stdout)
  let mem_str =
    string.append("mem: ", list.map(mem, int.to_string) |> string.join(", "))
  string.join(
    [
      cmd_str,
      cycle_str,
      pc_str,
      ptr_str,
      ptr_value_str,
      stdin_str,
      stdout_str,
      mem_str,
    ],
    ", ",
  )
}

pub type BfVmIrq {
  Halt(pc: Int)
  PointerUnderflow(pc: Int)
  PointerOverflow(pc: Int)
  StdinEmpty(pc: Int)
  Unimplemented(pc: Int, cmd: String)
  IllegalBranch(pc: Int)
  Other(pc: Int, cmd: String)
}

pub fn create_bfvm(code: String, stdin: String) -> BfVm {
  // remove visual characters
  let code = string.replace(code, " ", "")
  let code = string.replace(code, "\n", "")
  let code = string.replace(code, "\r", "")
  let code = string.replace(code, "\t", "")
  BfVm(code, 0, 0, 0, stdin, "", [0])
}

type FindBrError {
  UnmatchedBracket
}

fn find_matching_bracket(
  target: String,
  code: String,
  pc: Int,
  depth: Int,
) -> Result(Int, FindBrError) {
  // incremental: [ -> *]*, decrement: ] -> *[*
  let depth_dec_target = target
  let depth_inc_target = case target {
    "[" -> "]"
    "]" -> "["
    _ -> panic as "Invalid target"
  }
  let pc_move = case target {
    "[" -> -1
    "]" -> 1
    _ -> panic as "Invalid target"
  }
  let head = string.slice(code, pc, 1)
  case head {
    c if c == depth_inc_target -> {
      find_matching_bracket(target, code, pc + pc_move, depth + 1)
    }
    c if c == depth_dec_target -> {
      case depth == 0 {
        True -> Ok(pc)
        False -> find_matching_bracket(target, code, pc + pc_move, depth - 1)
      }
    }
    // empty
    "" -> Error(UnmatchedBracket)
    // ignore other characters
    _ -> {
      find_matching_bracket(target, code, pc + pc_move, depth)
    }
  }
}

pub fn step_bfvm(vm: BfVm) -> Result(BfVm, BfVmIrq) {
  // check if the pointer is out of bounds
  let expand_mem = case vm.ptr >= list.length(vm.mem) {
    True -> list.append(vm.mem, [0])
    False -> vm.mem
  }

  // command decode & execute
  case vm.pc >= string.length(vm.code) {
    // program end
    True -> Error(Halt(vm.pc))
    // program running
    False -> {
      let cmd = string.slice(vm.code, vm.pc, 1)
      case cmd {
        // increment pointer
        ">" ->
          Ok(BfVm(
            vm.code,
            vm.cycle + 1,
            vm.pc + 1,
            vm.ptr + 1,
            vm.stdin,
            vm.stdout,
            expand_mem,
          ))
        // decrement pointer
        "<" -> {
          case vm.ptr == 0 {
            // underflow pointer
            True -> Error(PointerUnderflow(vm.pc))
            // decrement pointer
            False ->
              Ok(BfVm(
                vm.code,
                vm.cycle + 1,
                vm.pc + 1,
                vm.ptr - 1,
                vm.stdin,
                vm.stdout,
                expand_mem,
              ))
          }
        }
        // increment memory
        "+" -> {
          let assert Ok(curr) = list.drop(expand_mem, vm.ptr) |> list.first
          let new_mem =
            list.flatten([
              list.take(expand_mem, vm.ptr),
              [curr + 1],
              list.drop(expand_mem, vm.ptr + 1),
            ])
          Ok(BfVm(
            vm.code,
            vm.cycle + 1,
            vm.pc + 1,
            vm.ptr,
            vm.stdin,
            vm.stdout,
            new_mem,
          ))
        }

        // decrement memory
        "-" -> {
          let assert Ok(curr) = list.drop(expand_mem, vm.ptr) |> list.first
          let new_mem =
            list.flatten([
              list.take(expand_mem, vm.ptr),
              [curr - 1],
              list.drop(expand_mem, vm.ptr + 1),
            ])
          Ok(BfVm(
            vm.code,
            vm.cycle + 1,
            vm.pc + 1,
            vm.ptr,
            vm.stdin,
            vm.stdout,
            new_mem,
          ))
        }
        // branch if zero
        "[" -> {
          let assert Ok(curr) = list.drop(expand_mem, vm.ptr) |> list.first
          // check if the current memory is zero
          case curr == 0 {
            // if not zero, continue
            False ->
              Ok(BfVm(
                vm.code,
                vm.cycle + 1,
                vm.pc + 1,
                vm.ptr,
                vm.stdin,
                vm.stdout,
                expand_mem,
              ))
            // if zero, skip to the matching ]
            True -> {
              case find_matching_bracket("]", vm.code, vm.pc + 1, 0) {
                Error(UnmatchedBracket) -> {
                  Error(IllegalBranch(vm.pc))
                }
                Ok(jump_pc) -> {
                  Ok(BfVm(
                    vm.code,
                    vm.cycle + 1,
                    jump_pc + 1,
                    vm.ptr,
                    vm.stdin,
                    vm.stdout,
                    expand_mem,
                  ))
                }
              }
            }
          }
        }
        // branch if not zero
        "]" -> {
          case find_matching_bracket("[", vm.code, vm.pc - 1, 0) {
            Error(UnmatchedBracket) -> {
              Error(IllegalBranch(vm.pc))
            }
            Ok(jump_pc) -> {
              Ok(BfVm(
                vm.code,
                vm.cycle + 1,
                jump_pc,
                vm.ptr,
                vm.stdin,
                vm.stdout,
                expand_mem,
              ))
            }
          }
        }
        "." -> {
          let assert Ok(c) = list.drop(expand_mem, vm.ptr) |> list.first
          let assert Ok(c) = string.utf_codepoint(c)
          let c = string.from_utf_codepoints([c])
          let new_stdout = string.append(vm.stdout, c)
          Ok(BfVm(
            vm.code,
            vm.cycle + 1,
            vm.pc + 1,
            vm.ptr,
            vm.stdin,
            new_stdout,
            expand_mem,
          ))
        }
        "," -> {
          case vm.stdin == "" {
            // stdin empty
            True -> Error(StdinEmpty(vm.pc))
            // read from stdin
            False -> {
              let c = string.slice(vm.stdin, 0, 1)
              let c = string.to_utf_codepoints(c)
              let assert Ok(c) = list.first(c)
              let c = string.utf_codepoint_to_int(c)
              let new_stdin = string.slice(vm.stdin, 1, string.length(vm.stdin))
              let new_mem =
                list.flatten([
                  list.take(expand_mem, vm.ptr),
                  [c],
                  list.drop(expand_mem, vm.ptr + 1),
                ])
              Ok(BfVm(
                vm.code,
                vm.cycle + 1,
                vm.pc + 1,
                vm.ptr,
                new_stdin,
                vm.stdout,
                new_mem,
              ))
            }
          }
        }
        cmd -> {
          Error(Unimplemented(vm.pc, cmd))
        }
      }
    }
  }
}

pub fn run_bfvm(vm: BfVm) -> Result(BfVm, BfVmIrq) {
  // to_string(vm) |> io.println
  case step_bfvm(vm) {
    Error(Halt(_)) -> {
      Ok(vm)
    }
    Error(PointerUnderflow(pc)) -> {
      io.println(string.append(
        "Error: Pointer underflow at pc: ",
        int.to_string(pc),
      ))
      panic
    }
    Error(Unimplemented(pc, cmd)) -> {
      io.println(
        string.append("Error: Unimplemented command '", cmd)
        <> string.append("' at pc: ", int.to_string(pc)),
      )
      panic
    }
    Error(PointerOverflow(pc)) -> {
      io.println(string.append(
        "Error: Pointer overflow at pc: ",
        int.to_string(pc),
      ))
      panic
    }
    Error(StdinEmpty(pc)) -> {
      io.println(string.append("Error: Stdin empty at pc: ", int.to_string(pc)))
      panic
    }
    Error(IllegalBranch(pc)) -> {
      io.println(string.append(
        "Error: Illegal branch at pc: ",
        int.to_string(pc),
      ))
      panic
    }
    Error(Other(pc, cmd)) -> {
      io.println(
        string.append("Error: Other error with command '", cmd)
        <> string.append("' at pc: ", int.to_string(pc)),
      )
      panic
    }
    Ok(new_vm) -> run_bfvm(new_vm)
  }
}

pub fn main() -> Nil {
  let src =
    "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
  let stdin = ""
  io.println("src: " <> src)
  io.println("stdin: " <> stdin)

  let vm = create_bfvm(src, "")
  let result = run_bfvm(vm)
  case result {
    Error(_) -> {
      io.println("Error")
    }
    Ok(vm) -> {
      io.println("stdout: " <> vm.stdout)
      io.println("vmstat: " <> to_string(vm))
    }
  }
}
