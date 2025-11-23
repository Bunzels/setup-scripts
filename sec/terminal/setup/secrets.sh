#!/usr/bin/env bash
# secrets.sh - only for automated installer (fetched by late_command)
# Must be chmod 600 on target; never put plaintext passwords here.

# ADMIN_USER defaults to "administrator" if not provided.
ADMIN_USER="administrator"

# Use hashed passwords (sha512). Generate with: mkpasswd -m sha-512 's76TsFy9'
# Example:
ROOT_HASH='$6$Fzd5c6JqxqqBhL3j$i3UCh/o0SSGYkU9k2Gsztpo.sZVnmuVunH.a859kCQ7L7KPvRI5Xk7Gr89m0erxuESGsYMObVBvIg5Jrh7lpH1'
ADMIN_HASH='$6$Fzd5c6JqxqqBhL3j$i3UCh/o0SSGYkU9k2Gsztpo.sZVnmuVunH.a859kCQ7L7KPvRI5Xk7Gr89m0erxuESGsYMObVBvIg5Jrh7lpH1'

export ROOT_HASH
export ADMIN_HASH
export ADMIN_USER