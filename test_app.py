"""
Simple test file for the Flask application.
This can be expanded with proper unit tests using pytest.
"""
import os
import sys

# Set environment variables before importing app
os.environ['DYNAMODB_TABLE_NAME'] = 'picus_data'
os.environ['AWS_DEFAULT_REGION'] = os.environ.get('AWS_DEFAULT_REGION', 'eu-central-1')

def test_app_import():
    """Test that the app can be imported successfully."""
    try:
        import app
        assert app.app is not None
        print("✓ App imports successfully")
        return True
    except Exception as e:
        print(f"✗ App import failed: {e}")
        return False

def test_handler_import():
    """Test that the handler can be imported successfully."""
    try:
        import handler
        assert handler.delete_item is not None
        print("✓ Handler imports successfully")
        return True
    except Exception as e:
        print(f"✗ Handler import failed: {e}")
        return False

if __name__ == '__main__':
    print("Running basic import tests...")
    app_test = test_app_import()
    handler_test = test_handler_import()
    
    if app_test and handler_test:
        print("\n✓ All basic tests passed!")
        sys.exit(0)
    else:
        print("\n✗ Some tests failed!")
        sys.exit(1)

