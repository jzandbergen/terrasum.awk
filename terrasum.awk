#!/usr/bin/awk -f
BEGIN {
  # PROCINFO["sorted_in"] = NOTE: do we want to set this?

  # notice holds potential non-fatal messages for the user.
  # eg. An "op" is not recognized, instruct the user to fix it.
  delete(notice)
}

func colorize(color, string) {
  # Thanks @JBlond!
  # https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124
  ansi_reset = "\033[0m"
  switch (color) {
    case "red":
      color_code = 31
      break
    case "green":
      color_code = 32
      break
    case "yellow":
      color_code = 33
      break
    default:
      color_code = 36
  }

  ansi_color = sprintf("\033[%sm", color_code)
  return sprintf("%s%s%s",ansi_color, string, ansi_reset)
}

###
### Print & skip
###
/will be read during apply/ { print $0; next }
/The condition could not be evaluated at this time, a result will be known/ { print $0; next }
/will perform the actions described above/ { print $0; next }
/will be accepted to approve/ { print $0; next }


###
### Find operations on resources and update "the array" with the change.
###
$0 ~ /^.+(will|must) be .+$/ {
  # running terragrunt on a single unit:
  # 15:52:12.322 STDOUT tofu: Changes to Outputs:
  #
  # vs, multi units:
  # 15:55:13.342 STDOUT [sandbox] tofu: Changes to Outputs:
  #                     ^^^^^^^^^
  #                 field 3 contains the unit
  # vs, plain tofu:
  # Changes to Outputs:
  #
  # note: some lines are ended with a ansi color reset code in color mode(default).
  #       ("\033[0m"). No biggie, that makes the code look pretty rad.
  switch ($0) {
    case /created(\033\[0m)?$/:
      op = "create"
      break
    case /updated in-place$/:
      op = "in-place update"
      break
    case /replaced(\033\[0m)?$/:
      op = "replace"
      break
    case /destroyed(\033\[0m)?$/:
      op = "destroy"
      break
    default:
      op = "unknown"
      msg = sprintf("Unknown op for line: %s\n", $0)
      notice[length(notice) + 1] = msg
      break
    }


  # Terragrunt single unit.
  if ($3 ~ "tofu:") {
    unit     = "./"
    resource = $6
  }

  # Terragrunt multiple units.
  if ($4 ~ "tofu:") {
    # This voodoo strips the colors from the string "[<unit>]" because actually
    # the string also contains ansi escape codes, something like:
    # "\033[0;38;5;66m[<unit>]", blegh!
    unit     = gensub(/\033\[[0-9;]*m\[([^]]+)\]/, "\\1", "g", $3) # try again, now without colors
    resource = $7
  }

  # Plain `tofu`
  if ($3 !~ "tofu:" && $4 !~ "tofu") {
    unit     = "."
    resource = $3
  }


  array[unit][op][idx[op]++] = resource
}

###
### Print output exactly as it comes in.
###
{
  print $0
}

###
### Post processing: Give a summary of changes seen
###
END {
  for (this_unit in array) {
    printf(">>> terrasum.awk @ unit: %s\n", this_unit)
    for (this_op in array[this_unit]) {
      switch (this_op) {
        case "create":
          colored_op = colorize("green", this_op)
          break
        case "in-place update":
          colored_op = colorize("yellow", this_op)
          break
        case "destroy":
          colored_op = colorize("red", this_op)
          break
        case "replace":
          colored_op = colorize("red", this_op)
          break
        case "unknown":
          colored_op = colorize("red", this_op)
          break
        default:
          colored_op = colorize("blue", this_op)
          break
      }

      for ( this_idx in array[this_unit][this_op] ) {
        printf(" - %14s: %s\n", colored_op, array[this_unit][this_op][this_idx])
      }
      printf("\n")
    }
  }

  # print potential notices
  if (length(notice) > 0) {
    printf("-- The following non-fatal errors occured:\n")
    for (notidx in notice) {
      printf("%s\n", notice[notidx])
    }
  }
}
