package wren;

import wren.MapEntry;

/**
 * A hash table mapping keys to values.
 * 
 * We use something very simple: open addressing with linear probing. The hash
 * table is an array of entries. Each entry is a key-value pair. If the key is
 * the special UNDEFINED_VAL, it indicates no value is currently in that slot.
 * Otherwise, it's a valid key, and the value is the value associated with it.
 * 
 * When entries are added, the array is dynamically scaled by GROW_FACTOR to
 * keep the number of filled slots under MAP_LOAD_PERCENT. Likewise, if the map
 * gets empty enough, it will be resized to a smaller array. When this happens,
 * all existing entries are rehashed and re-added to the new array.
 * 
 * When an entry is removed, its slot is replaced with a "tombstone". This is an
 * entry whose key is UNDEFINED_VAL and whose value is TRUE_VAL. When probing
 * for a key, we will continue past tombstones, because the desired key may be
 * found after them if the key that was removed was part of a prior collision.
 * When the array gets resized, all tombstones are discarded.
 */
typedef ObjMap = {
    > Obj,
    var obj:Obj;
    /**
     * The number of entries allocated.
     */
    var capacity:Int;
    /**
     * The number of entries in the map.
     */
    var count:Int;

    var entries:Array<MapEntry>;
}