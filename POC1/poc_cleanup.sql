
-- DO NOT RUN UNLESS SURE
drop user target cascade;
drop user source cascade;
purge tablespace users;
drop public database link source_link;
drop public database link target_link;
