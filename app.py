import torch
from transformers import AutoTokenizer, AutoModel
import numpy as np
import sqlite3
import faiss
import os

class OptimizedVectorSearch:
    def __init__(self, model_name='sentence-transformers/all-MiniLM-L6-v2', db_path='vector_search.db'):
        # Model initialization
        self.tokenizer = AutoTokenizer.from_pretrained(model_name)
        self.model = AutoModel.from_pretrained(model_name)
        
        # Database setup
        self.db_path = db_path
        self._init_database()
        
        # FAISS index for efficient similarity search
        self.dimension = self.model.config.hidden_size
        self.index = faiss.IndexFlatL2(self.dimension)
    
    def _init_database(self):
        """Initialize SQLite database for document storage"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS documents (
                    id INTEGER PRIMARY KEY,
                    text TEXT UNIQUE,
                    embedding BLOB
                )
            ''')
            conn.commit()
    
    def encode_document(self, document):
        """Generate embedding for a single document"""
        # Tokenize and generate embedding
        encoded_input = self.tokenizer(
            document, 
            padding=True, 
            truncation=True, 
            return_tensors='pt'
        )
        
        with torch.no_grad():
            model_output = self.model(**encoded_input)
        
        # Mean pooling and normalization
        embeddings = self._mean_pooling(model_output, encoded_input['attention_mask'])
        embedding = torch.nn.functional.normalize(embeddings, p=2, dim=1).numpy()[0]
        
        return embedding
    
    def _mean_pooling(self, model_output, attention_mask):
        """Perform mean pooling on model output"""
        token_embeddings = model_output.last_hidden_state
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        return torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(input_mask_expanded.sum(1), min=1e-9)
    
    def add_documents(self, documents):
        """Add documents to database and FAISS index"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            for doc in documents:
                try:
                    # Generate embedding
                    embedding = self.encode_document(doc)
                    
                    # Store in database
                    cursor.execute(
                        'INSERT OR IGNORE INTO documents (text, embedding) VALUES (?, ?)', 
                        (doc, embedding.tobytes())
                    )
                    
                    # Add to FAISS index
                    self.index.add(embedding.reshape(1, -1))
                
                except Exception as e:
                    print(f"Error adding document: {e}")
            
            conn.commit()
    
    def search(self, query, top_k=5):
        """Perform optimized vector search"""
        # Encode query
        query_embedding = self.encode_document(query)
        
        # FAISS search for fast similarity
        D, I = self.index.search(query_embedding.reshape(1, -1), top_k)
        
        # Retrieve documents from database
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            results = []
            
            for idx in I[0]:
                cursor.execute('SELECT text FROM documents WHERE rowid = ?', (idx+1,))
                doc = cursor.fetchone()
                
                if doc:
                    results.append({
                        'document': doc[0],
                        'similarity': 1 / (1 + D[0][np.where(I[0] == idx)[0]][0])
                    })
        
        return results

def main():
    # Example usage
    documents = [
        "Machine learning is a subset of artificial intelligence",
        "Deep learning uses neural networks with many layers",
        "Natural language processing helps computers understand human language",
        "Computer vision enables machines to interpret visual information",
        "Reinforcement learning involves training agents through rewards"
    ]
    
    # Initialize optimized vector search
    vector_search = OptimizedVectorSearch()
    
    # Add documents
    vector_search.add_documents(documents)
    
    # Perform search
    query = "AI and machine learning"
    results = vector_search.search(query)
    
    print(f"Search results for query: '{query}'")
    for result in results:
        print(f"Document: {result['document']}")
        print(f"Similarity: {result['similarity']:.4f}\n")

if __name__ == "__main__":
    main()