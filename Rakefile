namespace :test do
  desc "Run the IGSearch Tests for iOS"
  task :ios do
    system("xctool -workspace IGSearch.xcworkspace -scheme IGSearch -sdk iphonesimulator -configuration Release test -test-sdk iphonesimulator test")
  end
end

task :default => 'test:ios'