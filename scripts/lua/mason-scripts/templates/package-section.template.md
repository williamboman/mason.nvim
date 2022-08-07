{# include "parse_commit" #}

# {{ name }}

> {{ spec.desc }}

Homepage: {% url(spec.homepage) %}  
Languages: {% join(each(spec.languages, wrap "`")) " " %}  
Categories: {% join(each(spec.categories, wrap "`")) " " %}  

<details>
    <summary>History:</summary>

{% list(each(history, parse_commit)) %}
</details>

```
:MasonInstall {{ name }}
```
