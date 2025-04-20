import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type BfVm {
  BfVm(
    code: String,
    pc: Int,
    ptr: Int,
    stdin: String,
    stdout: String,
    mem: List(Int),
  )
}

pub type BfVmIrq {
  Halt(pc: Int)
  PointerUnderflow(pc: Int)
  PointerOverflow(pc: Int)
  StdinEmpty(pc: Int)
  Unimplemented(pc: Int, cmd: String)
  Other(pc: Int, cmd: String)
}

pub fn create_bfvm(code: String, stdin: String) -> BfVm {
  BfVm(code, 0, 0, stdin, "", [0])
}

pub fn step_bfvm(vm: BfVm) -> Result(BfVm, BfVmIrq) {
  // check if the pointer is out of bounds
  let mem = case vm.ptr >= list.length(vm.mem) {
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
          Ok(BfVm(vm.code, vm.pc + 1, vm.ptr + 1, vm.stdin, vm.stdout, mem))
        // decrement pointer
        "<" -> {
          case vm.ptr == 0 {
            // underflow pointer
            True -> Error(PointerUnderflow(vm.pc))
            // decrement pointer
            False ->
              Ok(BfVm(vm.code, vm.pc + 1, vm.ptr - 1, vm.stdin, vm.stdout, mem))
          }
        }
        // increment memory
        "+" -> {
          let assert Ok(curr) = list.drop(vm.mem, vm.ptr) |> list.first
          let new_mem =
            list.flatten([
              list.take(vm.mem, vm.ptr),
              [curr + 1],
              list.drop(vm.mem, vm.ptr + 1),
            ])
          Ok(BfVm(vm.code, vm.pc + 1, vm.ptr, vm.stdin, vm.stdout, new_mem))
        }

        // decrement memory
        "-" -> {
          let assert Ok(curr) = list.drop(vm.mem, vm.ptr) |> list.first
          let new_mem =
            list.flatten([
              list.take(vm.mem, vm.ptr),
              [curr - 1],
              list.drop(vm.mem, vm.ptr + 1),
            ])
          Ok(BfVm(vm.code, vm.pc + 1, vm.ptr, vm.stdin, vm.stdout, new_mem))
        }
        // branch if zero
        "[" -> {
          let assert Ok(curr) = list.drop(vm.mem, vm.ptr) |> list.first
          // search for matching ]
          todo
        }
        // branch if not zero
        "]" -> {
          let assert Ok(curr) = list.drop(vm.mem, vm.ptr) |> list.first
          todo
        }
        "." -> {
          let assert Ok(c) = list.drop(vm.mem, vm.ptr) |> list.first
          let assert Ok(c) = string.utf_codepoint(c)
          let c = string.from_utf_codepoints([c])
          let new_stdout = string.append(vm.stdout, c)
          Ok(BfVm(vm.code, vm.pc + 1, vm.ptr, vm.stdin, new_stdout, mem))
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
                  list.take(vm.mem, vm.ptr),
                  [c],
                  list.drop(vm.mem, vm.ptr + 1),
                ])
              Ok(BfVm(vm.code, vm.pc + 1, vm.ptr, new_stdin, vm.stdout, new_mem))
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
  case step_bfvm(vm) {
    Error(Halt(_)) -> {
      Ok(vm)
    }
    Error(PointerUnderflow(_)) -> {
      todo
    }
    Error(Unimplemented(_, _)) -> {
      todo
    }
    Error(PointerOverflow(_)) -> {
      todo
    }
    Error(StdinEmpty(_)) -> {
      todo
    }
    Error(Other(_, _)) -> {
      todo
    }
    Ok(new_vm) -> {
      run_bfvm(new_vm)
    }
  }
}

pub fn main() -> Nil {
  let hello =
    "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
  let vm = create_bfvm(hello, "")
  let result = run_bfvm(vm)
  case result {
    Error(_) -> {
      io.println("Error")
    }
    Ok(vm) -> {
      io.println(vm.stdout)
    }
  }
  io.println("Hello, Tanabata!")
  io.println("Tanabata is a Brainfuck interpreter written in Gleam.")
}
