202206180001
Tags: #bash_script

---

# while loop with increment in bash

```bash
#!/bin/bash

MONTH=1

while [[ ${MONTH} -le 12 ]]
do
        echo "Month: ${MONTH}"
        (( MONTH++ ))
		# alternative
		# let MONTH++
done
```

See:
```bash
help let
```

```bash
expr 1 + 1
```

---
## Links