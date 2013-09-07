desc "Run the IGSearch Tests for iOS"
task :test do
  system("xctool -workspace IGSearch.xcworkspace -scheme IGSearch -sdk iphonesimulator -configuration Release test -test-sdk iphonesimulator test")
end

task :default => 'test'