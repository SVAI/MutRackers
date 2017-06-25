"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
//our root app component
var core_1 = require("@angular/core");
var platform_browser_1 = require("@angular/platform-browser");
var platform_browser_animations_1 = require("@angular/platform-browser-animations");
var ngx_charts_1 = require("@swimlane/ngx-charts");
var data_ts_1 = require("../data.ts");
var App = (function () {
    function App() {
        this.view = [700, 400];
        // options
        this.showXAxis = true;
        this.showYAxis = true;
        this.gradient = false;
        this.showLegend = true;
        this.showXAxisLabel = true;
        this.xAxisLabel = 'Country';
        this.showYAxisLabel = true;
        this.yAxisLabel = 'Population';
        this.colorScheme = {
            domain: ['#5AA454', '#A10A28', '#C7B42C', '#AAAAAA']
        };
        Object.assign(this, { single: data_ts_1.single, multi: data_ts_1.multi });
    }
    App.prototype.onSelect = function (event) {
        console.log(event);
    };
    return App;
}());
App = __decorate([
    core_1.Component({
        selector: 'my-app',
        template: "\n    <ngx-charts-bar-horizontal\n      [view]=\"view\"\n      [scheme]=\"colorScheme\"\n      [results]=\"single\"\n      [gradient]=\"gradient\"\n      [xAxis]=\"showXAxis\"\n      [yAxis]=\"showYAxis\"\n      [legend]=\"showLegend\"\n      [showXAxisLabel]=\"showXAxisLabel\"\n      [showYAxisLabel]=\"showYAxisLabel\"\n      [xAxisLabel]=\"xAxisLabel\"\n      [yAxisLabel]=\"yAxisLabel\"\n      (select)=\"onSelect($event)\">\n    </ngx-charts-bar-horizontal>\n  "
    }),
    __metadata("design:paramtypes", [])
], App);
exports.App = App;
var AppModule = (function () {
    function AppModule() {
    }
    return AppModule;
}());
AppModule = __decorate([
    core_1.NgModule({
        imports: [platform_browser_1.BrowserModule, platform_browser_animations_1.BrowserAnimationsModule, ngx_charts_1.NgxChartsModule],
        declarations: [App],
        bootstrap: [App]
    })
], AppModule);
exports.AppModule = AppModule;
//# sourceMappingURL=app.js.map