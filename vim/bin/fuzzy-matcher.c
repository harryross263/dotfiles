#define _GNU_SOURCE

#include <stdlib.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <assert.h>
#include <ctype.h>

#define MATCH_ADJ_SLASH_SCORE 1
#define MATCH_IN_FILENAME_SCORE 5
#define MATCH_UNDER_MULT 2
#define MATCH_SLASH_MULT 3
#define MAX_PAT_LEN 200

struct match_pos {
  int score;
  const char *start_pos;
  int len;
};

#define MAX_RESULTS 100000
struct match_pos results[MAX_RESULTS];
int next_result_pos = 0;

int cmp (const void *a, const void *b) {
  return (((const struct match_pos *)b)->score - ((const struct match_pos *)a)->score);
}

/*
 * Ideas:
 * 1) prefer paths that have certain words in them, like 'core', or 'base'
 * 2) prefer paths close to currently open file
 */


inline int multiplier_for_end_of_match(char next_char, bool in_filename_part, char after_match) {
  int mult = 0;
  switch (next_char) {
    case '/':
      mult += MATCH_SLASH_MULT;
      break;

    case '_':
      mult += MATCH_UNDER_MULT;
      break;

    default:
      if (!isalnum(next_char))
        mult += 1;
  }

  if (mult)
  { 
    if (!isalnum(after_match)) 
      mult += 1;

    if (in_filename_part)
      mult += MATCH_IN_FILENAME_SCORE;
  }

  return mult;
}

const char *score_one (const char *fn_begin, const char *fn_pos, const char *pat_begin, const char *pat_pos) {
  int score             = 0;
  int run_length        = -1;
  char after_match = '\0';
  const char *last_slash = fn_begin;
  const char *starting_pos    = fn_pos;

  /* assume that we always start on a \r\n */
  assert(*fn_pos == '\n');
  fn_pos--;

  while (pat_pos >= pat_begin && fn_pos >= fn_begin) {
    switch(*fn_pos) {
      case '\n': goto filename_done;
      case '/' : 
        last_slash = fn_pos > last_slash ? fn_pos : last_slash;
    };

    if (*fn_pos == *pat_pos || (*pat_pos == '-' && *fn_pos == '_')) {
      run_length++;

      // give increasing scores for progressively longer runs
      // but break runs on '/' characters
      if (*fn_pos != '/') {
        score += run_length * 10;
      }
      else {
        if (run_length > 1)
          score += run_length * multiplier_for_end_of_match(*fn_pos, last_slash <= fn_pos, after_match);
        after_match = *fn_pos;
        run_length = -1;
      };

      if (last_slash < fn_pos) 
        score += MATCH_IN_FILENAME_SCORE;

      pat_pos--;
    }
    else {
      if (run_length > 1)
        score += run_length * multiplier_for_end_of_match(*fn_pos, last_slash <= fn_pos, after_match);
      after_match = *fn_pos;
      run_length = -1;
    }

    fn_pos--;
  }; 

  if (run_length > 1) {
    score += run_length * multiplier_for_end_of_match(*fn_pos, last_slash <= fn_pos, after_match);
  }

filename_done:
  fn_pos = memrchr(fn_begin, '\n', fn_pos - fn_begin + 1);

  if (pat_pos < pat_begin) {
    int i = next_result_pos++;

    score++;

    score = score * 1000 - (starting_pos - fn_pos);

    if (*(starting_pos - 1) == 'i')
      score += 2; // Prefer mlis

    results[i].score = score;
    if (fn_pos < fn_begin) {
      results[i].start_pos = fn_begin;
    } else {
      results[i].start_pos = fn_pos+1;
    };
    results[i].len       = starting_pos - results[i].start_pos + 1;

    if (next_result_pos > MAX_RESULTS) {
      fprintf (stderr, "too many results (> %i) for internal buffer\n", MAX_RESULTS);
      exit (1);
    };
  };

  return fn_pos;
}

void find_and_score_matches (char *filenames, char *filenames_end, char *pat) {
  char *pat_end = pat + (strlen (pat) - 1);

  const char *filenames_pos = filenames_end;

  while (filenames_pos >= filenames) {
    filenames_pos = score_one (filenames, filenames_pos, pat, pat_end);
  }
}

char *construct_pat(int argc, char *argv[]) {
  char *res = malloc (MAX_PAT_LEN * sizeof(char));
  if (res == NULL) {
    fprintf (stderr, "unable to malloc buffer for pat\n");
    exit (1);
  };

  if (argc == 3) {
    return (argv[2]);
  } else {
    char *pos = res;
    int str_size;
    int total_size = 0;
    char *tmp;

    // the first token should be at the end
    tmp = argv[2];
    for (int i = 2; i < argc - 1; i ++) {
      argv[i] = argv[i + 1];
    };
    argv[argc - 1] = tmp;
    
    for (int i = 2; i < argc; i++) {
      // add a slash if we've added at least one token and aren't done
      if (i > 2) { 
        *pos = '/';
        pos++;
      };

      str_size = strlen (argv[i]);
      total_size = total_size + str_size + 1;
      if (total_size > MAX_PAT_LEN) {
        fprintf (stderr, "pattern too long\n");
        exit (1);
      };

      strncpy (pos, argv[i], str_size);
      pos += str_size;
    };

    *pos = '\0';
    return (res);
  };
}

int main(int argc, char *argv[]) {
  if (argc < 3) {
    exit (0);
  };

  char *list_filename = argv[1];
  char *pat = construct_pat (argc, argv);

  // don't bother if the pattern is less than 2 characters
  if (strlen(pat) < 2)
    return 0;

  int  fp = open (list_filename, O_RDONLY);
  if (fp == -1) {
    fprintf (stderr, "unable to open %s\n", list_filename);
    exit (1);
  };

  struct stat list_filename_stat;
  fstat (fp, &list_filename_stat);

  char *filenames = mmap (NULL, list_filename_stat.st_size, PROT_READ, MAP_PRIVATE, fp, 0);
  if (filenames == MAP_FAILED) {
    fprintf (stderr, "unable to mmap %s\n", list_filename);
    exit (1);
  };
  find_and_score_matches (filenames, filenames + list_filename_stat.st_size - 1, pat);
  qsort (results, next_result_pos, sizeof (struct match_pos), cmp);

  // output a max of 1000 results
  if (next_result_pos > 1000) 
    next_result_pos = 1000;

  for (int i = 0; i < next_result_pos; i++) {
    write (1, results[i].start_pos, results[i].len);
  };
  exit (0);
}
