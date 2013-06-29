#include <sqlite3ext.h>
#include <assert.h>

int sqlite3_extension_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi);
void rank_init (int verbose);