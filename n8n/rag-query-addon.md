# RAG Query Add-on For The Telegram Tutor Workflow

The starter workflow currently sets `rag_context` to an empty JSON array in `Load Tutor Context`. This keeps the first Telegram MVP simple and testable.

When you are ready to enable curriculum retrieval, insert these nodes between `Load Tutor Context` and `Compute Pedagogy Policy`.

## Node 1: Build Retrieval Query

Use an LLM or Code node to produce:

```json
{
  "query": "earthquake plate boundary stress release middle school",
  "disaster_type": "earthquake",
  "max_difficulty": 3
}
```

For the first version, a Code node is enough:

```javascript
const data = $input.first().json;
const text = data.message_text.toLowerCase();

let disasterType = null;
if (text.includes('earthquake')) disasterType = 'earthquake';
if (text.includes('volcano')) disasterType = 'volcano';
if (text.includes('flood')) disasterType = 'flood';
if (text.includes('tsunami')) disasterType = 'tsunami';
if (text.includes('landslide')) disasterType = 'landslide';

return [{
  json: {
    ...data,
    retrieval_query: data.message_text,
    retrieval_disaster_type: disasterType,
    retrieval_max_difficulty: Math.max(1, Math.min(5, Number(data.preferred_difficulty || 3)))
  }
}];
```

## Node 2: Create Embedding

HTTP Request to OpenAI:

```json
{
  "model": "text-embedding-3-small",
  "input": "={{$json.retrieval_query}}"
}
```

Expected vector path:

```text
{{$json.data[0].embedding}}
```

## Node 3: Match Knowledge Chunks

Postgres query:

```sql
select *
from match_knowledge_chunks($1, 6, $2, $3);
```

Parameters:

```javascript
[
  $node["Create Embedding"].json.data[0].embedding,
  $node["Build Retrieval Query"].json.retrieval_disaster_type,
  $node["Build Retrieval Query"].json.retrieval_max_difficulty
]
```

Depending on your n8n Postgres node version, passing vectors as parameters may need casting. If so, pass the embedding as a string like:

```javascript
'[' + embedding.join(',') + ']'
```

and change the SQL to:

```sql
select *
from match_knowledge_chunks($1::vector, 6, $2, $3);
```

## Node 4: Attach RAG Context

Code node:

```javascript
const context = $node["Build Retrieval Query"].json;
const chunks = $input.all().map(item => item.json);

return [{
  json: {
    ...context,
    rag_context: chunks.map(chunk => ({
      content: chunk.content,
      citation: chunk.citation,
      concept_codes: chunk.concept_codes,
      disaster_type: chunk.disaster_type,
      difficulty: chunk.difficulty,
      similarity: chunk.similarity
    }))
  }
}];
```

Then connect this node to `Compute Pedagogy Policy`.

