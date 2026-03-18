//
//  LlamaBridge.h
//  StorytellingPracticeApp
//
//  Bridging header for llama.cpp C/C++ functions
//

#ifndef LlamaBridge_h
#define LlamaBridge_h

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declarations for llama.cpp types
typedef struct llama_model* llama_model_ptr;
typedef struct llama_context* llama_context_ptr;
typedef int llama_token;

// Model loading
typedef struct {
    int n_gpu_layers;
    int main_gpu;
    const char* tensor_split;
    int seed;
    int n_ctx;
    int n_batch;
    int n_threads;
    int n_threads_batch;
    int rope_scaling_type;
    float rope_freq_base;
    float rope_freq_scale;
    float yarn_ext_factor;
    float yarn_attn_factor;
    float yarn_beta_fast;
    float yarn_beta_slow;
    int yarn_orig_ctx;
    int n_keep;
    int n_draft;
    int n_chunks;
    int n_parallel;
    int n_sequences;
    float p_split;
    int n_gpu_layers_draft;
    int n_ctx_draft;
    int n_keep_draft;
    int n_chunks_draft;
    int n_parallel_draft;
    int n_sequences_draft;
    float p_split_draft;
    int n_threads_draft;
    int n_threads_batch_draft;
    int n_predict;
    int n_probs;
    int top_k;
    float top_p;
    float min_p;
    float tfs_z;
    float typical_p;
    float temp;
    int penalty_last_n;
    float penalty_repeat;
    float penalty_freq;
    float penalty_present;
    float penalty_range;
    float mirostat;
    float mirostat_tau;
    float mirostat_eta;
    int penalize_nl;
    int logit_bias;
    int n_probs_ex;
    int grammar;
    int grammar_rules;
    int grammar_rule_count;
    int grammar_sum_count;
    int rpc_servers;
    int rpc_servers_count;
    int rpc_token;
    int rpc_token_count;
    int rpc_parallel;
    int rpc_batch_size;
    int rpc_n_keep;
    int rpc_n_draft;
    int rpc_n_chunks;
    int rpc_n_parallel;
    int rpc_n_sequences;
    float rpc_p_split;
    int rpc_n_gpu_layers_draft;
    int rpc_n_ctx_draft;
    int rpc_n_keep_draft;
    int rpc_n_chunks_draft;
    int rpc_n_parallel_draft;
    int rpc_n_sequences_draft;
    float rpc_p_split_draft;
    int rpc_n_threads_draft;
    int rpc_n_threads_batch_draft;
    int rpc_n_predict;
    int rpc_n_probs;
    int rpc_top_k;
    float rpc_top_p;
    float rpc_min_p;
    float rpc_tfs_z;
    float rpc_typical_p;
    float rpc_temp;
    int rpc_penalty_last_n;
    float rpc_penalty_repeat;
    float rpc_penalty_freq;
    float rpc_penalty_present;
    float rpc_penalty_range;
    float rpc_mirostat;
    float rpc_mirostat_tau;
    float rpc_mirostat_eta;
    int rpc_penalize_nl;
    int rpc_logit_bias;
    int rpc_n_probs_ex;
    int rpc_grammar;
    int rpc_grammar_rules;
    int rpc_grammar_rule_count;
    int rpc_grammar_sum_count;
} llama_model_params;

typedef struct {
    int n_ctx;
    int n_batch;
    int n_threads;
    int n_threads_batch;
    int n_yarn_orig_ctx;
    float rope_freq_base;
    float rope_freq_scale;
    float yarn_ext_factor;
    float yarn_attn_factor;
    float yarn_beta_fast;
    float yarn_beta_slow;
    int yarn_orig_ctx;
    int type_k;
    int type_v;
    int mul_mat_q;
    int f16_kv;
    int logits_all;
    int embedding;
    int offload_kqv;
} llama_context_params;

// Model functions
llama_model_params llama_model_default_params(void);
llama_model_ptr llama_load_model_from_file(const char* path, llama_model_params params);
void llama_free_model(llama_model_ptr model);

// Context functions
llama_context_params llama_context_default_params(void);
llama_context_ptr llama_new_context_with_model(llama_model_ptr model, llama_context_params params);
void llama_free(llama_context_ptr ctx);

// Tokenization
int llama_tokenize(llama_model_ptr model, const char* text, int text_len, llama_token* tokens, int n_max_tokens, bool add_bos, bool special);
const char* llama_token_to_str(llama_model_ptr model, llama_token token);

// Generation
int llama_eval(llama_context_ptr ctx, const llama_token* tokens, int n_tokens, int n_past, int n_threads);
int llama_token_eos(llama_model_ptr model);
int llama_token_bos(llama_model_ptr model);
int llama_n_vocab(llama_model_ptr model);
int llama_n_ctx(llama_context_ptr ctx);
float* llama_get_logits(llama_context_ptr ctx);
int llama_sample_top_p_top_k(llama_context_ptr ctx, const int* last_n_tokens, int n_last_tokens, int top_k, float top_p, float temp, int repeat_penalty);
int llama_n_len(llama_context_ptr ctx);

#ifdef __cplusplus
}
#endif

#endif /* LlamaBridge_h */
