Pod::Spec.new do |s|
  s.name         = "GeoFire"
  s.version      = "4.1.6s"
  s.summary      = "Realtime location queries with Firebase."
  s.homepage     = "https://github.com/Snappers-tv/geofire-objc"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = "Firebase"
  s.source       = { :git => "https://github.com/Snappers-tv/geofire-objc.git", :tag => s.version.to_s }
  s.source_files = "GeoFire/**/*.{h,m}"
  s.documentation_url   = "https://geofire-ios.firebaseapp.com/docs/"
  #s.ios.deployment_target = '13.0'
  s.ios.dependency  'Firebase/Database'
  s.frameworks   = 'CoreLocation', 'FirebaseDatabase'
  s.requires_arc = true
  s.static_framework = true

  s.subspec 'Utils' do |utils|
    utils.source_files = [
      "GeoFire/**/GFUtils*.[mh]",
      "GeoFire/**/GFGeoQueryBounds*.[mh]",
      "GeoFire/**/GFGeoHashQuery*.[mh]",
      "GeoFire/**/GFGeoHash*.[mh]",
      "GeoFire/**/GFBase32Utils*.[mh]",
    ]
    utils.frameworks = 'CoreLocation'
  end
end
