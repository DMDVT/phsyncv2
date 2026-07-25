from app.models.social import Friendship, Notification, SharedMedia

def test_social_models_construct():
    friendship = Friendship(requester_id=1, addressee_id=2, status="pending")
    notification = Notification(user_id=1, type="friend_request", title="Request", body="Body", is_read=False)
    shared = SharedMedia(sender_id=1, recipient_id=2, file_path="x", file_name="x", file_size=1, media_type="photo", status="pending")
    assert friendship.status == "pending"
    assert notification.is_read is False
    assert shared.media_type == "photo"
