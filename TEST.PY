from moviepy.editor import VideoFileClip
import os


def compress_video(input_path, output_path, target_size_mb=20):
    # Cargar el video
    clip = VideoFileClip(input_path)

    # Obtener la duración del video en segundos
    duration = clip.duration

    # Calcular el bitrate necesario para alcanzar el tamaño deseado
    target_size_bytes = target_size_mb * 1024 * 1024
    target_bitrate = (target_size_bytes * 8) / duration / 1000  # en kbps

    # Ajustar la calidad del video
    clip.write_videofile(
        output_path,
        codec='libx264',  # Codec común para videos MP4
        bitrate=f'{int(target_bitrate)}k',
        audio_codec='aac'  # Codec para audio, puedes ajustar según sea necesario
    )

    print(f"Video comprimido guardado en {output_path}")


# Usar el script
input_video_path = 'Videos2.mp4'  # Cambia este nombre por el nombre del archivo de entrada
output_video_path = 'output_video.mp4'  # Nombre del archivo de salida

compress_video(input_video_path, output_video_path)