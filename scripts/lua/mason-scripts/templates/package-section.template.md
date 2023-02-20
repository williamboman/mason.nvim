# {{ name }}

> {{ spec.desc }}

Homepage: {% url(spec.homepage) %}  
Languages: {% join(each(spec.languages, wrap "`")) " " %}  
Categories: {% join(each(spec.categories, wrap "`")) " " %}  

```
:MasonInstall {{ name }}
```
