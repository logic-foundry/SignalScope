using Lucene.Net.Analysis.Standard;
using Lucene.Net.Documents;
using Lucene.Net.Index;
using Lucene.Net.Search;
using Lucene.Net.Store;
using Lucene.Net.Util;

// Create an index in memory
using var directory = new RAMDirectory();
using var analyzer = new StandardAnalyzer(LuceneVersion.LUCENE_48);
using var writer = new IndexWriter(
    directory,
    new IndexWriterConfig(LuceneVersion.LUCENE_48, analyzer)
);

var csvPath = @"..\20261117213000.gkg.csv";
var indexed = 0;

// Decouple ENUMs on another file late
const int ExpectedColumns = 27;
const int ArticleUrlColumn = 4;
const int OrganizationsColumn = 13;

// Is this the indexing part? How does it work?
foreach (var line in File.ReadLines(csvPath))
{
    var columns = line.Split('\t');

    // Make sure GDELT GKG fixed schema is applied
    if (columns.Length != ExpectedColumns)
        continue;

    writer.AddDocument(new Document
    {
        new TextField(
            "organizations",
            columns[OrganizationsColumn],
            Field.Store.YES),

        new StringField(
            "url",
            columns[ArticleUrlColumn],
            Field.Store.YES)
    });
    indexed++;
}

Console.WriteLine($"Indexed: {indexed}");

writer.Commit();

// Search for NVIDIA test
using var reader = writer.GetReader(applyAllDeletes: true);
var searcher = new IndexSearcher(reader);
var query = new TermQuery(new Term("organizations", "nvidia"));

var results = searcher.Search(query, reader.MaxDoc);

Console.WriteLine($"Matches: {results.TotalHits}");

var counts = new Dictionary<string, int>(
    StringComparer.OrdinalIgnoreCase
);

// This is the co-occurrence engine. Should be the heart of the operation
foreach (var hit in results.ScoreDocs)
{
    var doc = searcher.Doc(hit.Doc);
    var organizations = doc.Get("organizations");

    if (string.IsNullOrWhiteSpace(organizations))
        continue;

    var names = organizations
        .Split(';', StringSplitOptions.RemoveEmptyEntries |
                    StringSplitOptions.TrimEntries)
        .Distinct(StringComparer.OrdinalIgnoreCase);

    foreach (var name in names)
    {
        if (name.Equals("nvidia", StringComparison.OrdinalIgnoreCase))
            continue;

        counts[name] = counts.GetValueOrDefault(name) + 1;
    }
}

foreach (var item in counts.OrderByDescending(x => x.Value).Take(10))
{
    Console.WriteLine($"{item.Key}: {item.Value}");
}