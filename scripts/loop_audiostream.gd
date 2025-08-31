extends AudioStreamPlayer

func _ready() -> void:
	# Make sure the audio stream loops
	if stream:
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif stream is AudioStreamMP3:
			stream.loop = true
	
	# Auto-play when ready
	play()

func _on_finished() -> void:
	play()
