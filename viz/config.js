System.config({
  //use typescript for compilation
  transpiler: 'typescript',
  //typescript compiler options
  typescriptOptions: {
    emitDecoratorMetadata: true
  },
  //map tells the System loader where to look for things
  map: {
    app: "./src",
    '@angular/core': 'https://npmcdn.com/@angular/core@4.0.1/bundles/core.umd.js',
    '@angular/compiler': 'https://npmcdn.com/@angular/compiler@4.0.1/bundles/compiler.umd.js',
    '@angular/common': 'https://npmcdn.com/@angular/common@4.0.1/bundles/common.umd.js',
    '@angular/animations/browser': "https://npmcdn.com/@angular/animations@4.0.1/bundles/animations-browser.umd.js",
    '@angular/animations': "https://npmcdn.com/@angular/animations@4.0.1/bundles/animations.umd.js",
    '@angular/platform-browser-dynamic': 'https://npmcdn.com/@angular/platform-browser-dynamic@4.0.1/bundles/platform-browser-dynamic.umd.js',
    '@angular/platform-browser': 'https://npmcdn.com/@angular/platform-browser@4.0.1/bundles/platform-browser.umd.js',
    '@angular/platform-browser-animations': 'https://npmcdn.com/@angular/platform-browser@4.0.1/bundles/platform-browser-animations.umd.js',
    '@angular/forms': 'https://npmcdn.com/@angular/forms@4.0.1/bundles/forms.umd.js',
    '@angular/router': 'https://npmcdn.com/@angular/router@4.0.1/bundles/router.umd.js',
    'rxjs': 'https://npmcdn.com/rxjs@5.0.0',
    'moment': 'https://npmcdn.com/moment',
    'd3-array': 'https://npmcdn.com/d3-array',
    'd3-brush': 'https://npmcdn.com/d3-brush',
    'd3-shape': 'https://npmcdn.com/d3-shape',
    'd3-selection': 'https://npmcdn.com/d3-selection',
    'd3-color': 'https://npmcdn.com/d3-color',
    'd3-drag': 'https://npmcdn.com/d3-drag',
    'd3-transition': 'https://npmcdn.com/d3-transition',
    'd3-format': 'https://npmcdn.com/d3-format',
    'd3-force': 'https://npmcdn.com/d3-force',
    'd3-dispatch': 'https://npmcdn.com/d3-dispatch',
    'd3-path': 'https://npmcdn.com/d3-path',
    'd3-ease': 'https://npmcdn.com/d3-ease',
    'd3-timer': 'https://npmcdn.com/d3-timer',
    'd3-quadtree': 'https://npmcdn.com/d3-quadtree',
    'd3-interpolate': 'https://npmcdn.com/d3-interpolate',
    'd3-scale': 'https://npmcdn.com/d3-scale',
    'd3-time': 'https://npmcdn.com/d3-time',
    'd3-collection': 'https://npmcdn.com/d3-collection',
    'd3-time-format': 'https://npmcdn.com/d3-time-format',
    'd3-hierarchy': 'https://npmcdn.com/d3-hierarchy',
    '@swimlane/ngx-charts': 'https://npmcdn.com/@swimlane/ngx-charts'
  },
  //packages defines our app package
  packages: {
    app: {
      main: './bootstrap.ts',
      defaultExtension: 'ts'
    },
    'rxjs': {
      main: './bundles/Rx.js'
    }
  }
});
