package haxe.ui.containers;

import haxe.ui.core.MouseEvent;
import haxe.ui.core.Platform;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.util.Rectangle;
import haxe.ui.components.HScroll;
import haxe.ui.components.VScroll;
import haxe.ui.core.Component;
import haxe.ui.core.UIEvent;
import haxe.ui.layouts.DefaultLayout;
import haxe.ui.core.IClonable;
import haxe.ui.util.Size;

@:dox(icon="/icons/ui-scroll-pane-both.png")
class ScrollView extends Component implements IClonable<ScrollView> {
    public var _contents:Box;
    private var _hscroll:HScroll;
    private var _vscroll:VScroll;

    public function new() {
        super();
    }

    private override function createDefaults():Void {
        _defaultLayout = new ScrollViewLayout();
    }

    private override function create():Void {
        super.create();

        if (native == true) {
            updateScrollRect();
        } else {
            checkScrolls();
            //updateScrollRect();
        }
    }

    private override function createChildren():Void {
        super.createChildren();
    }

    private override function destroyChildren():Void {
        if (_hscroll != null) {
            removeComponent(_hscroll);
            _hscroll = null;
        }
        if (_vscroll != null) {
            removeComponent(_vscroll);
            _vscroll = null;
        }
    }

    private override function onReady():Void {
        super.onReady();
        checkScrolls();
        updateScrollRect();
    }

    private override function onResized():Void {
        checkScrolls();
        updateScrollRect();
    }

    @bindable public var vscrollPos(get, set):Float;
    private function get_vscrollPos():Float {
        if (_vscroll == null) {
            return 0;
        }
        return _vscroll.pos;
    }
    private function set_vscrollPos(value:Float):Float {
        if (_vscroll == null) {
            return value;
        }
        _vscroll.pos = value;
        handleBindings(["vscrollPos"]);
        return value;
    }

    @bindable public var hscrollPos(get, set):Float;
    private function get_hscrollPos():Float {
        if (_hscroll == null) {
            return 0;
        }
        return _hscroll.pos;
    }
    private function set_hscrollPos(value:Float):Float {
        if (_hscroll == null) {
            return value;
        }
        _hscroll.pos = value;
        handleBindings(["hscrollPos"]);
        return value;
    }

    public override function addComponent(child:Component):Component {
        var v = null;
        if (Std.is(child, HScroll) || Std.is(child, VScroll)) {
            //child.registerEvent(UIEvent.READY, _onScrollReady);
            v = super.addComponent(child);
        } else if (Std.is(child, Box) && _contents == null) {
            _contents = cast child;
            _contents.addClass("scrollview-contents");
            _contents.registerEvent(UIEvent.RESIZE, _onContentsResized);
            _contents.registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
            v = super.addComponent(_contents);
        } else {
            if (_contents == null) {
                _contents = new VBox();
                _contents.addClass("scrollview-contents");
                _contents.registerEvent(UIEvent.RESIZE, _onContentsResized);
                _contents.registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
                super.addComponent(_contents);
            }
            //trace(_contents);
            v = _contents.addComponent(child);
        }
        return v;
    }

    private function addComponentToSuper(child:Component):Component {
        return super.addComponent(child);
    }
    
    public var contents(get, null):Component;
    private function get_contents():Component {
        return _contents;
    }

    /*
    private function _onScrollReady(event:UIEvent) {
        event.target.unregisterEvent(UIEvent.READY, _onScrollReady);
        checkScrolls();
        updateScrollRect();
    }
    */
    
    private var horizontalConstraint(get, null):Component;
    private function get_horizontalConstraint():Component {
        return _contents;
    }
    
    private var verticalConstraint(get, null):Component;
    private function get_verticalConstraint():Component {
        return _contents;
    }
    
    private function _onMouseWheel(event:MouseEvent) {
        if (_vscroll != null) {
            if (event.delta > 0) {
                _vscroll.pos -= 60; // TODO: calculate this
                //_vscroll.animatePos(_vscroll.pos - 60);
            } else if (event.delta < 0) {
                _vscroll.pos += 60;
            }
        }
    }

    private function _onContentsResized(event:UIEvent) {
        checkScrolls();
        updateScrollRect();
    }

    private var hscrollOffset(get, null):Float;
    private function get_hscrollOffset():Float {
        return 0;
    }
    
    public function checkScrolls():Void {
        if (isReady == false
            || horizontalConstraint == null || horizontalConstraint.childComponents.length == 0
            || verticalConstraint == null || verticalConstraint.childComponents.length == 0
            || native == true) {
            return;
        }

        checkHScroll();
        checkVScroll();

        if (horizontalConstraint.componentWidth > layout.usableWidth) {
            if (_hscroll != null) {
                _hscroll.hidden = false;
                _hscroll.max = horizontalConstraint.componentWidth - layout.usableWidth - hscrollOffset;// _contents.layout.horizontalSpacing;
                _hscroll.pageSize = (layout.usableWidth / horizontalConstraint.componentWidth) * _hscroll.max;
            }
        } else {
            if (_hscroll != null) {
                _hscroll.hidden = true;
            }
        }

        if (verticalConstraint.componentHeight > layout.usableHeight) {
            if (_vscroll != null) {
                _vscroll.hidden = false;
                _vscroll.max = verticalConstraint.componentHeight - layout.usableHeight;
                _vscroll.pageSize = (layout.usableHeight / verticalConstraint.componentHeight) * _vscroll.max;
            }
        } else {
            if (_vscroll != null) {
                _vscroll.hidden = true;
            }
        }

        invalidateLayout();
    }

    private function checkHScroll() {
        if (componentWidth <= 0 || horizontalConstraint == null) {
            return;
        }

        if (horizontalConstraint.componentWidth > layout.usableWidth) {
            if (_hscroll == null) {
                _hscroll = new HScroll();
                _hscroll.percentWidth = 100;
                _hscroll.id = "scrollview-hscroll";
                _hscroll.registerEvent(UIEvent.CHANGE, _onScroll);
                addComponent(_hscroll);
            }
        } else {
            if (_hscroll != null) {
                removeComponent(_hscroll);
                _hscroll = null;
            }
        }
    }

    private function checkVScroll() {
        if (componentHeight <= 0 || verticalConstraint == null) {
            return;
        }

        if (verticalConstraint.componentHeight > layout.usableHeight) {
            if (_vscroll == null) {
                _vscroll = new VScroll();
                _vscroll.percentHeight = 100;
                _vscroll.id = "scrollview-vscroll";
                _vscroll.registerEvent(UIEvent.CHANGE, _onScroll);
                addComponent(_vscroll);
            }
        } else {
            if (_vscroll != null) { // TODO: bug in luxe backend
                removeComponent(_vscroll);
                _vscroll = null;
            }
        }
    }

    private function _onScroll(event:UIEvent) {
        updateScrollRect();
        handleBindings(["vscrollPos"]);
    }

    public function updateScrollRect() {
        if (_contents == null) {
            return;
        }

        var ucx = layout.usableWidth;
        var ucy = layout.usableHeight;

        var clipCX = ucx;
        if (clipCX > _contents.componentWidth) {
            clipCX = _contents.componentWidth;
        }
        var clipCY = ucy;
        if (clipCY > _contents.componentHeight) {
            clipCY = _contents.componentHeight;
        }

        var xpos:Float = 0;
        if (_hscroll != null) {
            xpos = _hscroll.pos;
        }
        var ypos:Float = 0;
        if (_vscroll != null) {
            ypos = _vscroll.pos;
        }

        var rc:Rectangle = new Rectangle(Std.int(xpos), Std.int(ypos), clipCX, clipCY);
        _contents.clipRect = rc;
    }
}

@:dox(hide)
class ScrollViewLayout extends DefaultLayout {
    public function new() {
        super();
    }

    private override function repositionChildren():Void {
        var contents:Component = component.findComponent("scrollview-contents", null, false, "css");
        if (contents == null) {
            return;
        }

        var hscroll:Component = component.findComponent("scrollview-hscroll");
        var vscroll:Component = component.findComponent("scrollview-vscroll");

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

        contents.left = paddingLeft;
        contents.top = paddingTop;
    }

    private override function get_usableSize():Size {
        var size:Size = super.get_usableSize();
        var hscroll:Component = component.findComponent("scrollview-hscroll");
        var vscroll:Component = component.findComponent("scrollview-vscroll");
        if (hscroll != null && hidden(hscroll) == false) {
            size.height -= hscroll.componentHeight;
        }
        if (vscroll != null && hidden(vscroll) == false) {
            size.width -= vscroll.componentWidth;
        }

        if (cast(component, ScrollView).native == true) {
            var contents:Component = component.findComponent("scrollview-contents", null, false, "css");
            if (contents != null && contents.componentHeight > size.height) {
                size.width -= Platform.vscrollWidth;
            }
            var contents:Component = component.findComponent("scrollview-contents", null, false, "css");
            if (contents != null && contents.componentWidth > size.width) {
                size.height -= Platform.hscrollHeight;
            }
        }

        return size;
    }

    public override function calcAutoSize():Size {
        var size:Size = super.calcAutoSize();
        var hscroll:Component = component.findComponent("scrollview-hscroll");
        var vscroll:Component = component.findComponent("scrollview-vscroll");
        if (hscroll != null && hscroll.hidden == false) {
            size.height += hscroll.componentHeight;
        }
        if (vscroll != null && vscroll.hidden == false) {
            size.width += vscroll.componentWidth;
        }

        var contents:Component = component.findComponent("scrollview-contents", null, false, "css");
        if (contents != null) {
            //size.width = contents.componentWidth;
        }
        return size;
    }
}