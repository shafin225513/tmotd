using Godot;

public partial class Player : CharacterBody3D
{
	private Camera3D _camera;

	public override void _Ready()
	{
		// 1. Force mouse capture on start
		Input.MouseMode = Input.MouseModeEnum.Captured;

		// 2. Setup Camera offset to sit above body mesh
		_camera = GetNodeOrNull<Camera3D>("Camera3D");
		if (_camera == null)
		{
			_camera = new Camera3D();
			AddChild(_camera);
		}
		
		// Elevate camera so it isn't trapped inside the capsule mesh
		_camera.Position = new Vector3(0, 0.8f, 0);
		_camera.MakeCurrent();
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		// Re-lock mouse on left click if window loses focus
		if (@event is InputEventMouseButton mouseBtn && mouseBtn.Pressed && mouseBtn.ButtonIndex == MouseButton.Left)
		{
			Input.MouseMode = Input.MouseModeEnum.Captured;
		}

		// Mouse Look
		if (@event is InputEventMouseMotion motion && Input.MouseMode == Input.MouseModeEnum.Captured)
		{
			RotateY(-motion.Relative.X * 0.003f);
			if (_camera != null)
			{
				_camera.RotateX(-motion.Relative.Y * 0.003f);
				Vector3 rot = _camera.Rotation;
				rot.X = Mathf.Clamp(rot.X, Mathf.DegToRad(-80f), Mathf.DegToRad(80f));
				_camera.Rotation = rot;
			}
		}

		// Unlock mouse on ESC
		if (@event is InputEventKey keyEvent && keyEvent.Pressed && keyEvent.Keycode == Key.Escape)
		{
			Input.MouseMode = Input.MouseModeEnum.Visible;
		}
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector3 velocity = Velocity;

		if (!IsOnFloor())
		{
			velocity.Y -= 9.8f * (float)delta;
		}

		Vector3 direction = Vector3.Zero;
		if (Input.IsKeyPressed(Key.W)) direction -= Transform.Basis.Z;
		if (Input.IsKeyPressed(Key.S)) direction += Transform.Basis.Z;
		if (Input.IsKeyPressed(Key.A)) direction -= Transform.Basis.X;
		if (Input.IsKeyPressed(Key.D)) direction += Transform.Basis.X;

		direction.Y = 0;
		direction = direction.Normalized();

		velocity.X = direction.X * 5.0f;
		velocity.Z = direction.Z * 5.0f;

		Velocity = velocity;
		MoveAndSlide();
	}
}
