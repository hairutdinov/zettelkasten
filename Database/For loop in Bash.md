202206131501
Tags: #bash_script

---

# For loop in Bash
```bash
# Generate and display a password for each parameter.
for USER_NAME in "${@}"
do
  PASSWORD="PASSWORD=$(date +%s%N | sha256sum | head -c18)"
  echo "Username: ${USER_NAME}"
  echo "Password: ${PASSWORD}"
  echo
done

```

---
## Links