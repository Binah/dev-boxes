
## Overview

This box was made with ubuntu-11.10-server 

### This box contains

* ruby
* percona 5.5
* rails
* cucumber
* rspec
* tmux
* git


### Cooking the box

#### build the box with:
```
vagrant basebox build 'ruby'
```

#### now you can:

- verify your box by running: 

```
vagrant basebox validate ruby

```
- export your vm to a .box file by running :
 
```
vagrant basebox export   ruby
```

### Runs the box

#### To import it into vagrant type:
```
vagrant box add 'ruby' 'ruby.box'
```

#### To use it:
```
vagrant init 'ruby'
vagrant up
vagrant ssh
```