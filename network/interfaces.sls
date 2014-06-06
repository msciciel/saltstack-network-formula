#!jinja|yaml

{% from "network/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('network:lookup')) %}

{% set interfaces = datamap.interfaces.def_entries %}

{%- macro set_p(paramname, dictvar) -%}
  {%- if paramname in dictvar -%}
- {{ paramname }}: {{ dictvar[paramname] }}
  {%- endif -%}
{%- endmacro -%}

{% if salt['pillar.get']('network:interfaces', False) %}
  {% set interfaces = interfaces + salt['pillar.get']('network:interfaces') %}
{% endif %}

{# http://stackoverflow.com/questions/4870346/can-a-jinja-variables-scope-extend-beyond-in-an-inner-block #}
{%- set vlanRequired = [] -%}

{% for n in interfaces %}
network-{{ n.name }}:
  network:
    - managed
    - name: {{ n.name }}
    - enabled: {{ n.enable|default(datamap.interfaces.default_values.enable) }}
    - proto: {{ n.proto|default(datamap.interfaces.default_values.proto) }}
    - type: {{ n.type|default(datamap.interfaces.default_values.type) }}
    {% for p in datamap.interfaces.params_supported %}
    {{ set_p(p, n) }}
    {% endfor %}
    {% if n.use is defined %}
    - use:
      {% for u in n.use %}
      - network: network-{{ u }}
      {% endfor %}
    {% endif %}
    {% if n.type == 'vlan' %}
    {% do vlanRequired.append(1) -%}
    - require:
      - pkg: vlan
    {% endif %}
{% endfor %}

{% if vlanRequired %}
vlan:
  pkg.installed
{% endif %}
