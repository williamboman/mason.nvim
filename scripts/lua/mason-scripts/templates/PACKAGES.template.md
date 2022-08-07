# Mason Package Index
> `:Mason`

{% list(each(packages, _.compose(link, _.prop("name")))) %}

{% render_each(packages) "./package-section.template.md" %}
---
<sub><sup>
[https://github.com/williamboman/mason.nvim](https://github.com/williamboman/mason.nvim)
</sup></sub>
