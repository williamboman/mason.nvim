{# include "parse_commit" #}

# {{ name }}

> {{ spec.desc }}

Homepage: {% url(spec.homepage) %}  
Languages: {% join(spec.languages) ", " %}  
Categories: {% join(spec.categories) ", " %}  

<details>
    <summary>History:</summary>

{% list(each(history, parse_commit)) %}
</details>

```
:MasonInstall {{ name }}
```
