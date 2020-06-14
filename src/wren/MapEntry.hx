package wren;

typedef MapEntry = {
    /**
     * The entry's key, or UNDEFINED_VAL if the entry is not in use.
     */
    var key:Value;
    /**
     * The value associated with the key. If the key is UNDEFINED_VAL, this will
     * be false to indicate an open available entry or true to indicate a
     * tombstone -- an entry that was previously in use but was then deleted.
     */
    var value:Value;
}