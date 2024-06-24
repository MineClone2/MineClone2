# `mcl_chests` API

When reading through this documentation, please keep in mind that the chest
animations are achieved by giving each chest node an entity, as Minetest (as of
5.8.1) doesn't support giving nodes animated meshes, only static ones.

Because of that, a lot of parameters passed through the exposed functions are
be related to nodes and entities.

Please refer to [Minetest documentation](http://api.minetest.net/) and the code
comments in `api.lua`.


## `mcl_chests.register_chest(basename, definition)`

This function allows for simple chest registration, used by both regular and
trapped chests.

* `basename` is a string that will be concatenated to form full nodenames for
  chests, for example `"mcl_chests:basename_small"`.
* `definition` is a key-value table, with the following fields:

```lua
{
    desc = S("Stone Chest"),
    -- Equivalent to `description` field of Item/Node definition.
    -- Will be shown as chest's name in the inventory.

    title = {
        small = S("Stone Chest") -- the same as `desc` if not specified
        double = S("Large Stone Chest") -- defaults to `"Large " .. desc`
    }
    -- These will be shown when opening the chest (in formspecs).
    
    longdesc = S(
        "Stone Chests are containers which provide 27 inventory slots. Stone Chests can be turned into" ..
        "large stone chests with double the capacity by placing two stone chests next to each other."
    ),
    usagehelp = S("To access its inventory, rightclick it. When broken, the items will drop out."),
    tt_help = S("27 inventory slots") .. "\n" .. S("Can be combined to a large stone chest"),
    -- Equivalent to `_doc_items_longdesc`, `_doc_items_usagehelp` and
    -- `_tt_help` fields of Item/Node definition. Shown in the tooltip and wiki.

    tiles = { 
        small = { "vl_stone_chests_small.png" },
        double = { "vl_stone_chests_double.png" },
        inv = {
            "vl_stone_chests_top.png",
            "vl_stone_chests_bottom.png",
            "vl_stone_chests_right.png",
            "vl_stone_chests_left.png",
            "vl_stone_chests_back.png",
            "vl_stone_chests_front.png"
        },
    },
    -- `small` and `double` fields contain the textures that will be applied to
    -- chest entities.
    -- `inv` field contains table of textures (6 in total, for each cube side),
    -- that will be used to render the chest "node" in the inventory.

    groups = {
        pickaxey = 1,
        stone = 1,
        material_stone = 1,
    },
    -- Equivalent to `groups` field of Item/Node definition. There is some table
    -- merging occuring internally, but it is purely for entity rendering.

    sounds = { 
        mcl_sounds.node_sound_stone_defaults(), -- defaults to `nil`
        "vl_stone_chests_sound" -- defaults to `"default_chest"`
    },
    -- First value is equivalent to `sounds` field of Item/Node definition.
    -- Second value is a sound prefix, from which the actual sounds will be
    -- concatenated (e.g. `vl_stone_chests_sound_open.ogg`). See `api.lua`.

    hardness = 4.0,
    -- Equivalent to `_mcl_blast_resistance` and `_mcl_hardness` fields of
    -- Item/Node definition. They are always equal for chests.

    hidden = false,
    -- Equivalent to `_doc_items_hidden` field of Item/Node definition.

    mesecons = { 
        receptor = { 
            state = mesecon.state.on,
            rules = mesecon.rules.pplate,
        },
    },
    -- Equivalent to `mesecons` field of Item/Node definition.

    on_rightclick = function(pos, node, clicker)
        mcl_util.deal_damage(clicker, 2)
    end,
    -- If provided, will be executed at the end of the actual `on_rightclick`
    -- function of the chest node.
    -- If `on_rightclick_left` or `on_rightclick_right` are not provided, this
    -- will also be what is executed for left and right double chest nodes,
    -- respectively.

    drop = "chest",
    -- If provided, the chest will not drop itself, but the item of the chest
    -- with that basename.

    canonical_basename = "chest",
    -- If provided, the chest will turn into chest with that basename in
    -- `on_construct`.
}
```

For usage examples, see `chests.lua` and `example.lua`.


## `mcl_chests.create_entity(pos, node_name, textures, param2, double, sound_prefix, mesh_prefix, animation_type, dir, entity_pos)`

This function creates a chest entity based on parameters:

* `pos` is the position vector.
* `node_name` is a string used in initialization data for the entity.
* `textures` is the entity textures.
* `param2` is a node param2, which then will be converted to entity direction.
* `double` is a boolean value for whether the chest is double or not.
* `sound_prefix` is a string, from which the actual sounds for the entity will
  be concatenated.
* `mesh_prefix` is the same thing as `sound_prefix`, but for meshes.
* `animation_type` is a string that will be used in `set_animation` method of
  chest entity.
* `dir` and `entity_pos` are number and vector values used to get entity info.

Returned value is either a luaentity, or `nil` if failed (in which case a
warning message gets written into the console).


## `find_or_create_entity(pos, node_name, textures, param2, double, sound_prefix, mesh_prefix, animation_type, dir, entity_pos)`

This function finds an existing entity, or creates one if failed. Parameters:

* `pos` is the position vector.
* `node_name` is a string used in initialization data for the entity.
* `textures` is the entity textures.
* `param2` is a node param2, which then will be converted to entity direction.
* `double` is a boolean value for whether the chest is double or not.
* `sound_prefix` is a string, from which the actual sounds for the entity will
  be concatenated.
* `mesh_prefix` is the same thing as `sound_prefix`, but for meshes.
* `animation_type` is a string that will be used in `set_animation` method of
  chest entity.
* `dir` and `entity_pos` are number and vector values used to get entity info.

Returned value is either a luaentity, or `nil` if failed (in which case a
warning message gets written into the console).


## `mcl_chests.select_and_spawn_entity(pos, node)`

This function is a simple wrapper for `mcl_chests.find_or_create_entity`,
getting most of the fields from node definition.

* `pos` is the position vector.
* `node` is a NodeRef.

Returned value is either a luaentity, or `nil` if failed (in which case a
warning message gets written into the console).


## `mcl_chests.no_rotate`

This function is equivalent to `screwdriver.disallow` and is used when a chest
can't be rotated, and is applied in `on_rotate` field of Node definition.


## `mcl_chests.simple_rotate(pos, node, user, mode, new_param2)`

This function allows for simple rotation with the entity being affected as well,
and is applied in `on_rotate` field of Node definition.


## `mcl_chests.open_chests`

This table contains all currently open chests, indexed by player name.

`nil` if player is not using a chest, and `{ pos = <chest node position> }`
otherwise (where position is a vector value).


## `mcl_chests.protection_check_move(pos, from_list, from_index, to_list, to_index, count, player)`

This function is called in `allow_metadata_inventory_move` field of Node
definition.


## `mcl_chests.protection_check_put_take(pos, listname, index, stack, player)`

This function is called in `allow_metadata_inventory_put` and
`allow_metadata_inventory_take` fields of Node definition.


## `mcl_chests.player_chest_open(player, pos, node_name, textures, param2, double, sound, mesh, shulker)`

This function opens a chest based on parameters:

* `player` is an ObjectRef.
* `pos` is the position vector.
* `node_name` is a string used in initialization data for the entity.
* `textures` is the entity textures.
* `param2` is a node param2, which then will be converted to entity direction.
* `double` is a boolean value for whether the chest is double or not.
* `sound` is a prefix string, from which the actual sounds for the entity will
  be concatenated.
* `mesh` is the same thing as `sound`, but for meshes.
* `shulker` is a boolean value for whether the chest is a shulker or not.


## `mcl_chests.player_chest_close(player)`

This function has to be called when a player closes a chest.

* `player` is an ObjectRef.


## `mcl_chests.chest_update_after_close(pos)`

This function is called when a chest is closed by `player_chest_close`.

* `pos` is the chest's position vector.


## `mcl_chests.is_not_shulker_box(stack)`

This function checks for whether `stack` is a shulker box, and returns `false`
if it is. Used internally to disallow putting shulker boxes into shulker boxes.

* `stack` is an ItemStack.
