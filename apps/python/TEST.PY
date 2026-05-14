from moviepy import VideoFileClip
import os


def compress_video(input_path, output_path, target_size_mb=20):
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"No existe el archivo: {input_path}")

    clip = VideoFileClip(input_path)

    duration = clip.duration  # segundos

    # Tamaño objetivo en bits
    target_size_bits = target_size_mb * 1024 * 1024 * 8

    # Reservar bitrate para audio (ej: 128 kbps)
    audio_bitrate = 128 * 1000  # bits por segundo

    # Calcular bitrate total permitido
    total_bitrate = target_size_bits / duration

    # Bitrate de video = total - audio
    video_bitrate = total_bitrate - audio_bitrate

    if video_bitrate <= 0:
        raise ValueError("El video es demasiado corto para ese tamaño objetivo")

    print(f"Bitrate video: {int(video_bitrate/1000)} kbps")

    clip.write_videofile(
        output_path,
        codec="libx264",
        bitrate=f"{int(video_bitrate/1000)}k",
        audio_codec="aac",
        audio_bitrate="128k",
        preset="medium"  # puedes usar 'slow' para mejor compresión
    )

    clip.close()
    print(f"✅ Video comprimido: {output_path}")


# Uso
compress_video("Videos2.mp4", "output_video.mp4", target_size_mb=20)