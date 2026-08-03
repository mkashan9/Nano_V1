# SAFE-03 decisions

- Reuse MED-02 assert/record shape; do not overload generation quota tables.
- Empty or unmatched hosts reject URLs; seed YouTube hosts for learning links.
- Gate `send_friend_request` and `insert_user_report`; expose
  `assert_community_message_allowed` for COM-04.
- Seed terms/limits in SQL; no authenticated writes to policy tables.
