# LogRocket React Native Module

## Getting started
`$ npm install @logrocket/react-native --save`

If you are using React Native < 0.60, link the package using react-native:
`npx react-native link @logrocket/react-native`

### Android

Add the maven repository to the `repositories` block of `build.gradle`:
```
maven { url "https://storage.googleapis.com/logrocket-maven/" }
```

### Expo plugin

> This package cannot be used in the "Expo Go" app because [it requires custom native code](https://docs.expo.io/workflow/customizing/).

After installing this npm package, add the [config plugin](https://docs.expo.io/guides/config-plugins/) to the [`plugins`](https://docs.expo.io/versions/latest/config/app/#plugins) array of your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "plugins": ["@logrocket/react-native"]
  }
}
```

Now you can build your app with [EAS Build](https://docs.expo.io/build/introduction/) or as described in the ["Adding custom native code"](https://docs.expo.io/workflow/customizing/) guide.

## Supported Features

| Feature                              | Android            | iOS                |
| ----------------------------         | ------------------ | ------------------ |
| Screen Capture                       | :heavy_check_mark: | :heavy_check_mark: |
| View Redaction                       | :heavy_check_mark: | :heavy_check_mark: |
| Touch Events                         | :heavy_check_mark: | :heavy_check_mark: |
| Identify and User Traits             | :heavy_check_mark: | :heavy_check_mark: |
| Network Requests & Responses         | :heavy_check_mark: | :heavy_check_mark: |
| Console Logs                         | :heavy_check_mark: | :heavy_check_mark: |
| Exceptions                           | :heavy_check_mark: | :heavy_check_mark: |
| Custom Events                        | :heavy_check_mark: | :heavy_check_mark: |
| getSessionURL                        | :heavy_check_mark: | :heavy_check_mark: |
| [Redux middleware][redux-middleware] | :heavy_check_mark: | :heavy_check_mark: |
| Connection quality config            | :heavy_check_mark: | :x:                |

LogRocket instruments the XmlHttpRequest and fetch APIs to capture network requests and responses.
For network sanitization, visit our docs: https://docs.logrocket.com/reference/network

LogRocket also automatically captures all messages logged to the console.
For configuration options see our docs: https://docs.logrocket.com/reference/console.

To use the redaction feature, first set the `testID` prop on any element you want redacted, e.g., `<Foo testID='RedactionString' />`
Then, when you call `init`, send the `testID` value as part of the `redactionTags` configuration option.

To enable only uploads when a wifi connection is active, use the `connectionType` configuration option with the value `WIFI`. Only supported on Android currently.

## Usage
```javascript
import LogRocket from '@logrocket/react-native';

LogRocket.init('YOUR_APP_ID', {
  network: {
    requestSanitizer: request => {
      if (request.headers['x-auth-token']) {
        request.headers['x-auth-token'] = '';
      }

      return request;
    },
  },
  connectionType: 'WIFI',
  console: {
    isEnabled: {
      info: false,
    },
    shouldAggregateConsoleErrors: true,
  },
  redactionTags: ['RedactionString'],
});

LogRocket.getSessionURL((url) => {
  console.log("LogRocket session URL: " + url);
})

LogRocket.identify('12345', {
  name: 'Rog Locket',
  email: 'roglocket@logrocket.com',
});

LogRocket.captureException(new Error('error'));

LogRocket.captureMessage('a custom message', {
  tags: { method: 'POST' }, 
  extra: { couponApplied: false, total: 42.99 }
});

LogRocket.track('PurchaseComplete', {
  revenue: 42.99,
  productCategory: 'Clothing',
  productSku: 4887369299,
  couponApplied: true,
  customerSegments: ['aef34b', '97cb20']
});
```

## Disabling Specific Platform SDKs

### Android

To disable the Android SDK add the following to your project's `react-native.config.js`:

```javascript
module.exports {
  dependencies: {
    '@logrocket/react-native': {
      platforms: {
        android: null,
      },
    },
  },
};
```


### iOS

To disable the iOS SDK add the following to your project's `react-native.config.js`:

```javascript
module.exports {
  dependencies: {
    '@logrocket/react-native': {
      platforms: {
        ios: null,
      },
    },
  },
};
```

Then run `cd ios/ && pod update` to ensure the Native SDK is removed as a dependency.

[redux-middleware]: https://docs.logrocket.com/reference/redux-logging
