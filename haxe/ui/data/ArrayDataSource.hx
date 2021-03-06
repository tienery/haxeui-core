package haxe.ui.data;

class ArrayDataSource<T> extends DataSource<T> {
    private var _array:Array<T> = new Array<T>();
    
    public function new() {
        super();
    }
    
    // overrides
    private override function handleGetSize():Int {
        return _array.length;
    }
    
    private override function handleGetItem(index:Int):T {
        return _array[index];
    }
    
    private override function handleAddItem(item:T):T {
        _array.push(item);
        return item;
    }
    
    private override function handleRemoveItem(item:T):T {
        _array.remove(item);
        return item;
    }
    
    private override function handleUpdateItem(index:Int, item:T):T {
        return _array[index] = item;
    }
}