package haxe.ui.containers;

import haxe.ui.components.HScroll;
import haxe.ui.components.VScroll;
import haxe.ui.core.BasicItemRenderer;
import haxe.ui.core.Component;
import haxe.ui.core.IClonable;
import haxe.ui.core.IDataComponent;
import haxe.ui.core.ItemRenderer;
import haxe.ui.core.Platform;
import haxe.ui.core.UIEvent;
import haxe.ui.data.DataSource;
import haxe.ui.layouts.DefaultLayout;
import haxe.ui.util.Rectangle;
import haxe.ui.util.Size;

class TableView extends ScrollView implements IDataComponent implements IClonable<TableView> {
    private var _header:Header;
    private var _itemRenderers:Array<ItemRenderer> = new Array<ItemRenderer>();
    
    public function new() {
        super();
        addClass("scrollview");
    }
    
    private override function createDefaults():Void {
        _defaultLayout = new TableViewLayout();
    }

    private override function createChildren():Void {
        super.createChildren();
    }

    private override function create():Void {
        super.create();
        var vbox:VBox = new VBox();
        vbox.addClass("tableview-contents");
        addComponent(vbox);
    }
    
    private override function onReady():Void {
        super.onReady();
        
        if (_header != null && _itemRenderers.length < _header.childComponents.length) {
            var delta:Int = _header.childComponents.length - _itemRenderers.length;
            for (n in 0...delta) {
                addComponent(new BasicItemRenderer());
            }
        }
        
        syncUI();
    }

    private override function onResized():Void {
        super.onResized();
        sizeItems();
    }

    #if haxeui_html5 // TODO: should be in backend somehow
    private var lastScrollLeft = 0;
    #end
    public override function addComponent(child:Component):Component {
        var v = null;
        if (Std.is(child, Header)) {
            _header = cast(child, Header);
            _header.registerEvent(UIEvent.RESIZE, _onHeaderResized);
            
            
            #if haxeui_html5 // TODO: should be in backend somehow
            if (native == true) {
                this.element.onscroll = function(e) {
                    if (lastScrollLeft != this.element.scrollLeft) {
                        lastScrollLeft = this.element.scrollLeft;
                        _onHeaderResized(null);
                    }
                }
            }
            #end
            
            v = addComponentToSuper(child);
            if (_dataSource != null) {
                syncUI();
            }
        } else if (Std.is(child, ItemRenderer)) {
            #if haxeui_luxe
            child.hide();
            #end
            _itemRenderers.push(cast(child, ItemRenderer));
        } else if (Std.is(child, VScroll)) {
            child.includeInLayout = false;
            super.addComponent(child);
        } else {
            v = super.addComponent(child);
        }
        return v;
    }
    
    private function _onHeaderResized(event:UIEvent) {
        /*
        checkScrolls();
        updateScrollRect();
        */

        #if haxeui_html5 // TODO: this should be in the backend somehow
        updateNativeHeaderClip();
        #end
    }
    
    #if haxeui_html5
    private function updateNativeHeaderClip() {
        if (native == true) {
            if (_header != null) {
                var ucx = layout.usableWidth;
                var xpos = this.element.scrollLeft;// _hscroll.pos;
                var clipCX = ucx;
                if (clipCX > _header.componentWidth) {
                    clipCX = _header.componentWidth;
                }
                if (xpos > 0) { // TODO: bit hacky - should use style or calc
                    _header.left = 2;
                    xpos++;
                } else {
                    _header.left = 1;
                }
                var rc:Rectangle = new Rectangle(Std.int(xpos), Std.int(0), clipCX, _header.componentHeight);
                _header.clipRect = rc;
            }
        }
    }
    #end
    
    private override function get_horizontalConstraint():Component {
        return _header;
    }
    
    private override function get_verticalConstraint():Component {
        return _contents;
    }
    
    private override function get_hscrollOffset():Float {
        return 2;
    }
    
    private var _dataSource:DataSource<Dynamic>;
    public var dataSource(get, set):DataSource<Dynamic>;
    private function get_dataSource():DataSource<Dynamic> {
        return _dataSource;
    }
    private function set_dataSource(value:DataSource<Dynamic>):DataSource<Dynamic> {
        _dataSource = value;
        syncUI();
        return value;
    }

    private function syncUI() {
        if (_dataSource == null || _header == null || _contents == null || _itemRenderers.length < _header.childComponents.length) {
            return;
        }
        
        contents.lockLayout(true);
        
        var delta = _dataSource.size - itemCount;
        if (delta > 0) { // not enough items
            for (n in 0...delta) {
                var hbox:HBox = new HBox();
                hbox.addClass("tableview-row");
                for (n in 0..._header.childComponents.length) {
                    hbox.addComponent(_itemRenderers[n].cloneComponent());
                }
                addComponent(hbox);
            }
        } else if (delta < 0) { // too many items
            while (delta < 0) {
                _contents.removeComponent(_contents.childComponents[_contents.childComponents.length - 1]); // remove last
                delta++;
            }
        }
        
        for (n in 0..._dataSource.size) {
            var row:HBox = cast(_contents.childComponents[n], HBox);
            //row.addClass(n % 2 == 0 ? "even" : "odd");
            var data:Dynamic = _dataSource.get(n);
            for (c in 0..._header.childComponents.length) {
                var item:ItemRenderer = cast(row.childComponents[c], ItemRenderer);
                item.addClass(n % 2 == 0 ? "even" : "odd");
                item.percentWidth = null;
                item.componentWidth = _header.childComponents[c].componentWidth - 2;
                var textData:String = Reflect.field(data, _header.childComponents[c].id);
                var reset:Bool = false;
                if (textData != null && data.text == null) {
                    data.text = textData;
                    reset = true;
                }
                item.data = data;
                if (reset) {
                    data.text = null;
                }
            }
        }

        sizeItems();
        
        contents.unlockLayout(true);
    }
    
    private function sizeItems() {
        contents.lockLayout(true);
        
        for (row in _contents.childComponents) {
            for (c in 0..._header.childComponents.length) {
                var item = row.childComponents[c];
                item.percentWidth = null;
                item.componentWidth = _header.childComponents[c].componentWidth - 2;
                item.height = row.componentHeight;
            }
        }
        
        contents.unlockLayout(true);
    }
    
    public var itemCount(get, null):Int;
    private function get_itemCount():Int {
        if (_contents == null) {
            return 0;
        }
        return _contents.childComponents.length;
    }
    
    private override function _onScroll(event:UIEvent) {
        updateScrollRect();
    }
    
    public override function updateScrollRect() {
        var rc:Rectangle = null;

        var ucx = layout.usableWidth;
        var ucy = layout.usableHeight;
        
        var xpos:Float = 0;
        if (_hscroll != null) {
            xpos = _hscroll.pos;
        }
        
        var ypos:Float = 0;
        if (_vscroll != null) {
            ypos = _vscroll.pos;
        }
        
        if (_header != null && (native == false || native == null)) {
            var clipCX = ucx;
            if (clipCX > _header.componentWidth) {
                clipCX = _header.componentWidth;
            }
            var rc:Rectangle = new Rectangle(Std.int(xpos + 1), Std.int(1), clipCX, _header.componentHeight);
            _header.clipRect = rc;
        } else {
            #if haxeui_html5
            updateNativeHeaderClip();
            #end
        }
        
        if (_contents != null) {
            var clipCX = ucx;
            if (clipCX > _contents.componentWidth) {
                clipCX = _contents.componentWidth;
            }
            var clipCY = ucy;
            if (clipCY > _contents.componentHeight) {
                clipCY = _contents.componentHeight;
            }
            
            var rc:Rectangle = new Rectangle(Std.int(xpos + 0), Std.int(ypos), clipCX, clipCY);
            _contents.clipRect = rc;
        }
    }
}

class TableViewLayout extends DefaultLayout {
    public function new() {
        super();
    }
    
    private override function resizeChildren() {
        super.resizeChildren();
        var vscroll:Component = component.findComponent(VScroll);
        var header:Header = component.findComponent(Header);
        if (vscroll != null) {
            var offsetY:Float = 0;
            if (header != null) {
                offsetY += header.componentHeight;
            }
            
            vscroll.componentHeight = usableHeight + offsetY;
        }
    }
    
    private override function repositionChildren():Void {
        var header:Header = component.findComponent(Header);
        if (header != null) {
            header.left = paddingLeft + marginLeft(header) - marginRight(header);
            header.top = paddingTop + marginTop(header) - marginBottom(header);
        }
        
        var hscroll:Component = component.findComponent(HScroll);
        var vscroll:Component = component.findComponent(VScroll);

        var ucx = innerWidth;
        var ucy = innerHeight;

        if (hscroll != null && hidden(hscroll) == false) {
            hscroll.left = paddingLeft;
            hscroll.top = ucy - hscroll.componentHeight + paddingBottom;
        }

        if (vscroll != null && hidden(vscroll) == false) {
            vscroll.left = ucx - vscroll.componentWidth + paddingRight;
            vscroll.top = paddingTop;
        }
        
        var contents:Component = component.findComponent("tableview-contents", null, false, "css");
        if (contents != null) {
            var offsetY:Float = 0;
            if (header != null) {
                offsetY += header.componentHeight;
            }
            contents.left = paddingLeft + marginLeft(contents) - marginRight(contents);
            contents.top = paddingTop + marginTop(contents) - marginBottom(contents) + offsetY;
        }
    }
    
    private override function get_usableSize():Size {
        var size:Size = super.get_usableSize();
        var hscroll:Component = component.findComponent(HScroll);
        var vscroll:Component = component.findComponent(VScroll);
        if (hscroll != null && hidden(hscroll) == false) {
            size.height -= hscroll.componentHeight;
        }
        if (vscroll != null && hidden(vscroll) == false) {
            size.width -= vscroll.componentWidth;
        }

        var header:Header = component.findComponent(Header);
        if (header != null) {
            size.height -= header.componentHeight;
        }
        size.height += 1;
        size.width += 1;
        if (cast(component, TableView).native == true) {
            var contents:Component = component.findComponent("tableview-contents", null, false, "css");
            if (contents != null && contents.componentHeight > size.height) {
                size.width -= Platform.vscrollWidth;
            }

            if (contents != null && contents.componentWidth > size.width) {
                size.height -= Platform.hscrollHeight;
            }
        }

        return size;
    }

    public override function calcAutoSize():Size {
        var size:Size = super.calcAutoSize();
        var hscroll:Component = component.findComponent(HScroll);
        var vscroll:Component = component.findComponent(VScroll);
        if (hscroll != null && hscroll.hidden == false) {
            size.height += hscroll.componentHeight;
        }
        if (vscroll != null && vscroll.hidden == false) {
            size.width += vscroll.componentWidth;
        }
        return size;
    }
}