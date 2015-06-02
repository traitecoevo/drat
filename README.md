# traitecoevo/drat

Our [drat](https://github.com/eddelbuettel/drat) repository 

First, install `drat.builder` with:

```
drat:::add("traitecoevo")
install.packages("drat.builder")
```

Install a helper script to somewhere in your `PATH`:
```
drat.builder::install_script("~/bin")
```

Then update from the shell with 

```
drat.builder
```

Or from R with

```
drat.builder::build()
```
