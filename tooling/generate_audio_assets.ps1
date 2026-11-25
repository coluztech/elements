$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.IO;

public static class ElementShiftAudioAssets
{
    const int Rate = 22050;

    static void WriteWave(string path, double seconds, Func<double, double> sample)
    {
        int count = (int)(Rate * seconds);
        Directory.CreateDirectory(Path.GetDirectoryName(path));
        using (var writer = new BinaryWriter(File.Create(path)))
        {
            writer.Write(new char[] { 'R','I','F','F' });
            writer.Write(36 + count * 2);
            writer.Write(new char[] { 'W','A','V','E','f','m','t',' ' });
            writer.Write(16); writer.Write((short)1); writer.Write((short)1);
            writer.Write(Rate); writer.Write(Rate * 2); writer.Write((short)2); writer.Write((short)16);
            writer.Write(new char[] { 'd','a','t','a' }); writer.Write(count * 2);
            for (int i = 0; i < count; i++)
            {
                double t = (double)i / Rate;
                double value = Math.Max(-1, Math.Min(1, sample(t)));
                writer.Write((short)(value * 32767));
            }
        }
    }

    static double Note(double t, double frequency, double decay)
    {
        return Math.Sin(2 * Math.PI * frequency * t) * Math.Exp(-decay * t);
    }

    public static void Generate(string root)
    {
        WriteWave(Path.Combine(root, "sfx", "collect.wav"), 0.34,
            t => 0.30 * (Note(t, 880, 10) + 0.55 * Note(t, 1320, 12)));
        WriteWave(Path.Combine(root, "sfx", "switch.wav"), 0.22,
            t => 0.32 * (Note(t, 330 - 120 * t, 18) + 0.2 * Note(t, 990, 24)));
        WriteWave(Path.Combine(root, "sfx", "level_complete.wav"), 0.9,
            t => {
                double[] notes = { 523.25, 659.25, 783.99, 1046.5 };
                int index = (int)(t / 0.19);
                if (index >= notes.Length) return 0;
                double local = t - index * 0.19;
                return 0.24 * (Note(local, notes[index], 5) + 0.32 * Note(local, notes[index] * 2, 8));
            });
        WriteWave(Path.Combine(root, "sfx", "respawn.wav"), 0.28,
            t => 0.26 * (Note(t, 440 - 300 * t, 12) + 0.28 * Note(t, 220, 18)));

        double[] roots = { 130.81, 110.00, 87.31, 98.00 };
        double[] thirds = { 164.81, 164.81, 130.81, 146.83 };
        double[] fifths = { 196.00, 220.00, 174.61, 196.00 };
        double[] melody = { 392.00, 329.63, 349.23, 392.00, 440.00, 392.00, 349.23, 329.63 };
        WriteWave(Path.Combine(root, "music", "world1.wav"), 8.0,
            t => {
                int bar = Math.Min(3, (int)(t / 2.0));
                double local = t % 2.0;
                double pad = 0.10 * (Note(t, roots[bar], 0) + Note(t, thirds[bar], 0) + Note(t, fifths[bar], 0));
                double beatTime = t % 1.0;
                int beat = (int)(t % 8.0);
                double pluck = 0.09 * Note(beatTime, melody[beat], 3.8);
                double pulse = 0.88 + 0.12 * Math.Sin(2 * Math.PI * local / 2.0);
                double edge = Math.Min(1, Math.Min(t / 0.18, (8.0 - t) / 0.18));
                return (pad * pulse + pluck) * Math.Max(0, edge);
            });
    }
}
'@

[ElementShiftAudioAssets]::Generate((Join-Path $PSScriptRoot '..\assets\audio'))
