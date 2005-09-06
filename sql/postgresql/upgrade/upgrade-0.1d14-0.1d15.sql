-- 
-- packages/dotlrn-ecommerce/sql/postgresql/upgrade/upgrade-0.1d14-0.1d15.sql
-- 
-- @author Roel Canicula (roelmc@pldtdsl.net)
-- @creation-date 2005-09-06
-- @arch-tag: 22b40de7-ea7d-4da0-8c15-88b20ba71f02
-- @cvs-id $Id$
--

create table dotlrn_ecommerce_application_assessment_map (
	rel_id		integer references membership_rels on delete cascade not null,
	session_id	integer references as_sessions on delete cascade not null
);

create index dotlrn_ecommerce_application_assessment_map_rel_id_idx
on dotlrn_ecommerce_application_assessment_map (rel_id);

create index dotlrn_ecommerce_application_assessment_map_session_id_idx
on dotlrn_ecommerce_application_assessment_map (session_id);

create unique index dotlrn_ecommerce_application_assessment_map_un
on dotlrn_ecommerce_application_assessment_map (rel_id, session_id);