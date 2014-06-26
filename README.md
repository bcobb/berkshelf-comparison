# Berkshelf Comparison

This repo contains three scripts to help normalize and compare the existing Berkshelf API with the Berkshelf endpoint provided by Chef Supermarket.

I highly recommend installing [`jq`](http://stedolan.github.io/jq/) to aid in analyzing the resulting JSON from a shell.

These scripts are only tested on ruby 2.0. If you don't `bundle` before running, just be sure to have the `chef` gem installed.

# Putting it all together

```shell
$ ruby berkshelf.rb | jq . > berkshelf.json
$ ruby supermarket.rb | jq . > supermarket.json
$ diff -U 1000 berkshelf.json supermarket.json | view -
```

# berkshelf.rb

Produces a list of normalized cookbooks present in the Berkshelf API. They are normalized in the sense that the list is sorted by name, a cookbook's versions are sorted by version comparison, and a cookbook version's dependencies are sorted by name.

## Usage

```shell
$ ruby berkshelf.rb
```

# supermarket.rb

Produces a list of normalized cookbooks present in both the Berkshelf API and in Supermarket's Berkshelf API. The list is normalized in the same way as that produced by berkshelf.rb, so `diff` output (with some generous context) should make sense.

## Usage

```shell
$ ruby supermarket.rb
```

## comparison.rb

Useful as a way to look at only those cookbooks which have discrepancies. This was the first script I wrote, and while it helped me get my head around how to compare these two similar-but-divergent APIs, I don't know how useful it is going forward.

It generates a list of cookbooks which appear to have discrepancies between the Berkshelf version and the Supermarket version. Each item of the list is a map with cookbook and cookbook version info. One example is:

```json
{
  "discrepancies": [
    "1.0.5"
  ],
  "missing": false,
  "versions": {
    "1.0.4": {
      "berkshelf": {
        "sudo": ">= 0.0.0"
      },
      "supermarket": {
        "sudo": ">= 0.0.0"
      }
    },
    "1.0.5": {
      "berkshelf": {
        "sudo": ">= 0.0.0"
      },
      "supermarket": {}
    },
    "1.0.7": {
      "berkshelf": {
        "sudo": ">= 0.0.0"
      },
      "supermarket": {
        "sudo": ">= 0.0.0"
      }
    }
  },
  "identical": false,
  "name": "ad-auth"
}
```

### Usage

```shell
$ ruby comparison.rb
```

With `jq`, you can get a rough idea of how much the two APIs differ:

```shell
$ ruby comparison.rb | jq length # how many cookbooks have discrepancies?
$ ruby comparison.rb | jq 'map(.discrepancies | length) | add' # how many total discrepancies are there?
```

