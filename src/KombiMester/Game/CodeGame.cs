namespace KombiMester.Game;

/// <summary>What the pegs look like. Only the looks change; the game is the same.</summary>
public enum PegStyle { Colors, Animals }

/// <summary>How one peg of a guess did: not in the code, in the code but elsewhere, or in the right place.</summary>
public enum Mark { Miss, Present, Exact }

/// <summary>A checked guess: the pegs (0–5) and one mark per peg, in the same order.</summary>
public sealed record Guess(IReadOnlyList<int> Pegs, IReadOnlyList<Mark> Marks)
{
    public int Exact => Marks.Count(m => m == Mark.Exact);
    public int Present => Marks.Count(m => m == Mark.Present);
    public bool IsRight => Exact == Pegs.Count;
}

/// <summary>One peg as the child sees it. <see cref="Emoji"/> is null for plain colours.</summary>
public sealed record PegLook(string Name, string? Emoji);

/// <summary>
/// The code-breaking game: a hidden code of four pegs out of six kinds, and ten tries to find it.
/// On the easy code every peg is different; on the hard code the same peg may come up to four times.
/// </summary>
public sealed class CodeGame
{
    public const int Length = 4;
    public const int Kinds = 6;
    public const int MaxTries = 10;

    private static readonly PegLook[] ColorPegs =
    [
        new("rød", null), new("blå", null), new("grøn", null),
        new("gul", null), new("lilla", null), new("sort", null),
    ];

    private static readonly PegLook[] AnimalPegs =
    [
        new("hund", "🐶"), new("kat", "🐱"), new("frø", "🐸"),
        new("kylling", "🐥"), new("gris", "🐷"), new("panda", "🐼"),
    ];

    private readonly Random _random;
    private readonly List<Guess> _guesses = [];
    private int[] _secret = [];

    public CodeGame(Random? random = null) => _random = random ?? new Random();

    public static IReadOnlyList<PegLook> Looks(PegStyle style) => style == PegStyle.Animals ? AnimalPegs : ColorPegs;

    /// <summary>Whether the same peg may appear more than once in the code (and in a guess).</summary>
    public bool Repeats { get; private set; }

    public IReadOnlyList<int> Secret => _secret;
    public IReadOnlyList<Guess> Guesses => _guesses;
    public int TriesLeft => MaxTries - _guesses.Count;

    public bool IsWon => _guesses.Count > 0 && _guesses[^1].IsRight;
    public bool IsLost => !IsWon && _guesses.Count >= MaxTries;
    public bool IsOver => IsWon || IsLost;

    /// <summary>Hides a new code and forgets the guesses.</summary>
    public void NewGame(bool repeats)
    {
        Repeats = repeats;
        _guesses.Clear();
        _secret = repeats
            ? Enumerable.Range(0, Length).Select(_ => _random.Next(Kinds)).ToArray()
            : Enumerable.Range(0, Kinds).OrderBy(_ => _random.Next()).Take(Length).ToArray();
    }

    /// <summary>Four pegs, and on the easy code no peg twice.</summary>
    public bool IsAllowed(IReadOnlyList<int> pegs) =>
        pegs.Count == Length
        && pegs.All(p => p is >= 0 and < Kinds)
        && (Repeats || pegs.Distinct().Count() == Length);

    public Guess Check(IReadOnlyList<int> pegs)
    {
        if (IsOver) throw new InvalidOperationException("The game is over.");
        if (!IsAllowed(pegs)) throw new ArgumentException("Not a valid guess.", nameof(pegs));

        var guess = new Guess(pegs.ToArray(), Score(_secret, pegs));
        _guesses.Add(guess);
        return guess;
    }

    /// <summary>
    /// Marks each peg of the guess. Pegs in the right place are found first; the rest count as
    /// "present" only while the code still has an unmatched peg of that kind, from left to right.
    /// So a code with one red and a guess with two reds marks only one of them.
    /// </summary>
    public static Mark[] Score(IReadOnlyList<int> secret, IReadOnlyList<int> guess)
    {
        var marks = new Mark[guess.Count];
        var unmatched = new int[Kinds];

        for (var i = 0; i < guess.Count; i++)
        {
            if (guess[i] == secret[i]) marks[i] = Mark.Exact;
            else unmatched[secret[i]]++;
        }

        for (var i = 0; i < guess.Count; i++)
        {
            if (marks[i] == Mark.Exact || unmatched[guess[i]] == 0) continue;
            marks[i] = Mark.Present;
            unmatched[guess[i]]--;
        }

        return marks;
    }
}
