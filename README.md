## terrasum.awk

Tired of scrolling through endless lines of `terragrunt` or `tofu` plans?
Be tired no mo' bro! Use **terrasum.awk**! It hands you a summary at the end of
the plan or plans!

## How to use?

Drop `terrasum.awk` somewhere in your `${PATH}` and b00m! Bob's your uncle!
How's that for a fingerlickin' fancy pants installation experience?!

Next up, pipe those bad boys straight trough `terrasum.awk`:
```bash
tofu plan | terrasum.awk

# Or show off like a frickin' pro
terragrunt plan --filter sandbox | terrasum.awk
```


Indulge in the bliss of a simple summary without wanting to gouge your eyes out
each time you're grinding through bazillions lines of state mumbo jumbo. Catch
those resource re-creates that will bring down prod like the champ you are!

Peace!
