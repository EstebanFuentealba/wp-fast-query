drop table if exists bbcl_dwh;

/*==============================================================*/
/* table: bbcl_dwh                                              */
/*==============================================================*/
create table bbcl_dwh
(
   id                   int not null auto_increment,
   post_author_id       int,
   post_date            datetime,
   post_title           text,
   post_status          varchar(20),
   post_name            varchar(200),
   guid                 varchar(255),
   post_type            varchar(20),
   post_link            varchar(255),
   post_year            int,
   post_month           int,
   author_name          varchar(150),
   author_display_name  varchar(150),
   categories           text,
   categories_slugs     text,
   categories_ids       text,
   tags                 text,
   tags_slugs           text,
   tags_ids             text,
   images               text,
   images_ids           text,
   primary key (id)
) ENGINE = MYISAM CHARACTER SET utf8 COLLATE utf8_general_ci; 




INSERT INTO bbcl_dwh (
        ID,
        post_author_id,
        post_date,
        post_title,
        post_status,
        post_name,
        guid,
        post_type,
        post_link,
        post_year,
        post_month,
        author_name,
        author_display_name,
        categories,
        categories_slugs,
        categories_ids,
        tags,
        tags_slugs,
        tags_ids,
        images,
        images_ids
)
SELECT  P.ID,
        P.post_author AS 'post_author_id',
        P.post_date,
        P.post_title,
        P.post_status,
        P.post_name,
        P.guid,
        P.post_type,
        CONCAT('/', 
          DATE_FORMAT(P.post_date,'%Y'),'/',
          DATE_FORMAT(P.post_date,'%m'),'/',
          DATE_FORMAT(P.post_date,'%d'),'/', 
          P.post_name,'.shtml') as 'post_link',
        DATE_FORMAT(P.post_date,'%Y') AS 'post_year',
        DATE_FORMAT(P.post_date,'%m') AS 'post_month',
        A.user_nicename AS 'author_name',
        A.display_name AS 'author_display_name',
        (
          SELECT CONCAT('["',group_concat( T.name separator  '","'),'"]')
          FROM wp_terms T 
            INNER JOIN wp_term_taxonomy TT 
              ON T.term_id = TT.term_id
            INNER JOIN wp_term_relationships R
              ON R.term_taxonomy_id = TT.term_taxonomy_id
          WHERE R.object_id = P.ID
            AND TT.taxonomy='category'
        ) AS 'categories',
        (
          SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
          FROM wp_terms T 
            INNER JOIN wp_term_taxonomy TT 
              ON T.term_id = TT.term_id
            INNER JOIN wp_term_relationships R
              ON R.term_taxonomy_id = TT.term_taxonomy_id
          WHERE R.object_id = P.ID
            AND TT.taxonomy='category'
        ) AS 'categories_slugs',
        (
          SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
          FROM wp_terms T 
            INNER JOIN wp_term_taxonomy TT 
              ON T.term_id = TT.term_id
            INNER JOIN wp_term_relationships R
              ON R.term_taxonomy_id = TT.term_taxonomy_id
          WHERE R.object_id = P.ID
            AND TT.taxonomy='category'
        ) AS 'categories_ids',
        (
          SELECT CONCAT('["',group_concat(T.name separator  '","'),'"]')
          FROM wp_terms T 
            INNER JOIN wp_term_taxonomy TT 
              ON T.term_id = TT.term_id
            INNER JOIN wp_term_relationships R
              ON R.term_taxonomy_id = TT.term_taxonomy_id
          WHERE R.object_id = P.ID
            AND TT.taxonomy='post_tag'
        ) AS 'tags',
        (
          SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
          FROM wp_terms T 
            INNER JOIN wp_term_taxonomy TT 
              ON T.term_id = TT.term_id
            INNER JOIN wp_term_relationships R
              ON R.term_taxonomy_id = TT.term_taxonomy_id
          WHERE R.object_id = P.ID
            AND TT.taxonomy='post_tag'
        ) AS 'tags_slugs',
        (
          SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
          FROM wp_terms T 
            INNER JOIN wp_term_taxonomy TT 
              ON T.term_id = TT.term_id
            INNER JOIN wp_term_relationships R
              ON R.term_taxonomy_id = TT.term_taxonomy_id
          WHERE R.object_id = P.ID
            AND TT.taxonomy='post_tag'
        ) AS 'tags_ids',
        (
          SELECT CONCAT('["',group_concat(substring_index(PO.guid,'/wp-content',-1) separator  '","'),'"]')
          FROM wp_postmeta AS PM 
            INNER JOIN wp_posts AS PO 
              ON PM.meta_value=PO.ID  
          WHERE PM.post_id = P.ID 
            AND PM.meta_key = '_thumbnail_id' 
        ) AS 'images',
        (
          SELECT CONCAT('["',group_concat(PO.ID separator  '","'),'"]')
          FROM wp_postmeta AS PM 
            INNER JOIN wp_posts AS PO 
              ON PM.meta_value=PO.ID  
          WHERE PM.post_id = P.ID 
            AND PM.meta_key = '_thumbnail_id' 
        ) AS 'images_ids'
FROM  wp_users A 
  INNER JOIN wp_posts P 
    ON P.post_author = A.ID
WHERE P.post_status='publish' 
  AND P.post_type='post'
ORDER BY P.post_date ASC;


CREATE INDEX dwh_year ON bbcl_dwh (post_year);
CREATE INDEX dwh_month ON bbcl_dwh (post_month);
ALTER TABLE  bbcl_dwh ADD FULLTEXT  `title_text` (
`post_title`
)




--## TRIGGER INSERT
DELIMITER |
CREATE TRIGGER onAddedPost AFTER INSERT ON wp_posts
FOR EACH ROW BEGIN
  IF NEW.post_status = 'publish' THEN
    INSERT INTO bbcl_dwh (
            ID,
            post_author_id,
            post_date,
            post_title,
            post_status,
            post_name,
            guid,
            post_type,
            post_link,
            post_link_note,
            post_year,
            post_month,
            author_name,
            author_display_name,
            categories,
            categories_slugs,
            categories_ids,
            tags,
            tags_slugs,
            tags_ids,
            images,
            images_ids
    )
    SELECT  P.ID,
            P.post_author AS 'post_author_id',
            P.post_date,
            P.post_title,
            P.post_status,
            P.post_name,
            P.guid,
            P.post_type,
            CONCAT('/', 
              DATE_FORMAT(P.post_date,'%Y'),'/',
              DATE_FORMAT(P.post_date,'%m'),'/',
              DATE_FORMAT(P.post_date,'%d'),'/', 
              P.post_name,'.shtml') as 'post_link',
            CONCAT('/notas/', 
              DATE_FORMAT(P.post_date,'%Y'),'/',
              DATE_FORMAT(P.post_date,'%m'),'/',
              DATE_FORMAT(P.post_date,'%d'),'/', 
              P.post_name,'.shtml') as 'post_link_note',
            DATE_FORMAT(P.post_date,'%Y') AS 'post_year',
            DATE_FORMAT(P.post_date,'%m') AS 'post_month',
            A.user_nicename AS 'author_name',
            A.display_name AS 'author_display_name',
            (
              SELECT CONCAT('["',group_concat( T.name separator  '","'),'"]')
              FROM wp_terms T 
                INNER JOIN wp_term_taxonomy TT 
                  ON T.term_id = TT.term_id
                INNER JOIN wp_term_relationships R
                  ON R.term_taxonomy_id = TT.term_taxonomy_id
              WHERE R.object_id = P.ID
                AND TT.taxonomy='category'
            ) AS 'categories',
            (
              SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
              FROM wp_terms T 
                INNER JOIN wp_term_taxonomy TT 
                  ON T.term_id = TT.term_id
                INNER JOIN wp_term_relationships R
                  ON R.term_taxonomy_id = TT.term_taxonomy_id
              WHERE R.object_id = P.ID
                AND TT.taxonomy='category'
            ) AS 'categories_slugs',
            (
              SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
              FROM wp_terms T 
                INNER JOIN wp_term_taxonomy TT 
                  ON T.term_id = TT.term_id
                INNER JOIN wp_term_relationships R
                  ON R.term_taxonomy_id = TT.term_taxonomy_id
              WHERE R.object_id = P.ID
                AND TT.taxonomy='category'
            ) AS 'categories_ids',
            (
              SELECT CONCAT('["',group_concat(T.name separator  '","'),'"]')
              FROM wp_terms T 
                INNER JOIN wp_term_taxonomy TT 
                  ON T.term_id = TT.term_id
                INNER JOIN wp_term_relationships R
                  ON R.term_taxonomy_id = TT.term_taxonomy_id
              WHERE R.object_id = P.ID
                AND TT.taxonomy='post_tag'
            ) AS 'tags',
            (
              SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
              FROM wp_terms T 
                INNER JOIN wp_term_taxonomy TT 
                  ON T.term_id = TT.term_id
                INNER JOIN wp_term_relationships R
                  ON R.term_taxonomy_id = TT.term_taxonomy_id
              WHERE R.object_id = P.ID
                AND TT.taxonomy='post_tag'
            ) AS 'tags_slugs',
            (
              SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
              FROM wp_terms T 
                INNER JOIN wp_term_taxonomy TT 
                  ON T.term_id = TT.term_id
                INNER JOIN wp_term_relationships R
                  ON R.term_taxonomy_id = TT.term_taxonomy_id
              WHERE R.object_id = P.ID
                AND TT.taxonomy='post_tag'
            ) AS 'tags_ids',
            (
              SELECT CONCAT('["',group_concat(substring_index(PO.guid,'/wp-content',-1) separator  '","'),'"]')
              FROM wp_postmeta AS PM 
                INNER JOIN wp_posts AS PO 
                  ON PM.meta_value=PO.ID  
              WHERE PM.post_id = P.ID 
                AND PM.meta_key = '_thumbnail_id' 
            ) AS 'images',
            (
              SELECT CONCAT('["',group_concat(PO.ID separator  '","'),'"]')
              FROM wp_postmeta AS PM 
                INNER JOIN wp_posts AS PO 
                  ON PM.meta_value=PO.ID  
              WHERE PM.post_id = P.ID 
                AND PM.meta_key = '_thumbnail_id' 
            ) AS 'images_ids'
    FROM  wp_users A 
      INNER JOIN wp_posts P 
        ON P.post_author = A.ID
      LEFT JOIN contadorvisitas C
        ON P.ID = C.idnoticia 
    WHERE P.post_status='publish' 
      AND P.post_type='post'
      AND P.ID = NEW.ID
    ORDER BY P.post_date ASC;

  END IF;
END
|
DELIMITER ;





--## TRIGGER UPDATE

DELIMITER |
CREATE TRIGGER onEditedPost AFTER UPDATE ON wp_posts
FOR EACH ROW BEGIN

  IF NEW.post_status = 'publish' THEN
    IF (SELECT COUNT(*)
        FROM bbcl_dwh
        WHERE ID = NEW.ID
        ) > 0 THEN

      UPDATE bbcl_dwh
        SET post_author_id = NEW.post_author,
              post_date = NEW.post_date,
              post_title = NEW.post_title,
              post_status = NEW.post_status,
              post_name = NEW.post_status,
              post_modified = NEW.post_modified,
              guid = NEW.guid,
              post_type = NEW.post_type,
              post_link =  CONCAT('/', 
                DATE_FORMAT(NEW.post_date,'%Y'),'/',
                DATE_FORMAT(NEW.post_date,'%m'),'/',
                DATE_FORMAT(NEW.post_date,'%d'),'/', 
                NEW.post_name,'.shtml'),
              post_year = DATE_FORMAT(NEW.post_date,'%Y'),
              post_month = DATE_FORMAT(NEW.post_date,'%m'),
              author_name = (SELECT user_nicename FROM `wp_users` WHERE ID=NEW.post_author LIMIT 1),
              categories = (
                SELECT CONCAT('["',group_concat( T.name separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = NEW.ID
                  AND TT.taxonomy='category'
              ),
              categories_slugs = (
                SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = NEW.ID
                  AND TT.taxonomy='category'
              ),
              categories_ids = (
                SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = NEW.ID
                  AND TT.taxonomy='category'
              ),
              tags = (
                SELECT CONCAT('["',group_concat(T.name separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = NEW.ID
                  AND TT.taxonomy='post_tag'
              ),
              tags_slugs = (
                SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = NEW.ID
                  AND TT.taxonomy='post_tag'
              ),
              tags_ids = (
                SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = NEW.ID
                  AND TT.taxonomy='post_tag'
              ),
              images = (
                SELECT CONCAT('["',group_concat(substring_index(PO.guid,'/wp-content',-1) separator  '","'),'"]')
                FROM wp_postmeta AS PM 
                  INNER JOIN wp_posts AS PO 
                    ON PM.meta_value=PO.ID  
                WHERE PM.post_id = NEW.ID 
                  AND PM.meta_key = '_thumbnail_id' 
              ),
              images_ids = (
                SELECT CONCAT('["',group_concat(PO.ID separator  '","'),'"]')
                FROM wp_postmeta AS PM 
                  INNER JOIN wp_posts AS PO 
                    ON PM.meta_value=PO.ID  
                WHERE PM.post_id = NEW.ID 
                  AND PM.meta_key = '_thumbnail_id' 
              )
      WHERE ID = NEW.ID;
    ELSE 
      INSERT INTO bbcl_dwh (
              ID,
              post_author_id,
              post_date,
              post_title,
              post_status,
              post_name,
              post_modified,
              guid,
              post_type,
              post_link,
              post_year,
              post_month,
              visitas,
              author_name,
              categories,
              categories_slugs,
              categories_ids,
              tags,
              tags_slugs,
              tags_ids,
              images,
              images_ids
      )
      SELECT  P.ID,
              P.post_author AS 'post_author_id',
              P.post_date,
              P.post_title,
              P.post_status,
              P.post_name,
              P.post_modified,
              P.guid,
              P.post_type,
              CONCAT('/', 
                DATE_FORMAT(P.post_date,'%Y'),'/',
                DATE_FORMAT(P.post_date,'%m'),'/',
                DATE_FORMAT(P.post_date,'%d'),'/', 
                P.post_name,'.shtml') as 'post_link',
              CONCAT('/notas/', 
                DATE_FORMAT(P.post_date,'%Y'),'/',
                DATE_FORMAT(P.post_date,'%m'),'/',
                DATE_FORMAT(P.post_date,'%d'),'/', 
                P.post_name,'.shtml') as 'post_link_note',
              DATE_FORMAT(P.post_date,'%Y') AS 'post_year',
              DATE_FORMAT(P.post_date,'%m') AS 'post_month',
              COALESCE(C.visitas, 0) AS 'visitas' ,
              A.user_nicename AS 'author_name',
              (
                SELECT CONCAT('["',group_concat( T.name separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = P.ID
                  AND TT.taxonomy='category'
              ) AS 'categories',
              (
                SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = P.ID
                  AND TT.taxonomy='category'
              ) AS 'categories_slugs',
              (
                SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = P.ID
                  AND TT.taxonomy='category'
              ) AS 'categories_ids',
              (
                SELECT CONCAT('["',group_concat(T.name separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = P.ID
                  AND TT.taxonomy='post_tag'
              ) AS 'tags',
              (
                SELECT CONCAT('["',group_concat(T.slug separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = P.ID
                  AND TT.taxonomy='post_tag'
              ) AS 'tags_slugs',
              (
                SELECT CONCAT('["',group_concat(R.term_taxonomy_id separator  '","'),'"]')
                FROM wp_terms T 
                  INNER JOIN wp_term_taxonomy TT 
                    ON T.term_id = TT.term_id
                  INNER JOIN wp_term_relationships R
                    ON R.term_taxonomy_id = TT.term_taxonomy_id
                WHERE R.object_id = P.ID
                  AND TT.taxonomy='post_tag'
              ) AS 'tags_ids',
              (
                SELECT CONCAT('["',group_concat(substring_index(PO.guid,'/wp-content',-1) separator  '","'),'"]')
                FROM wp_postmeta AS PM 
                  INNER JOIN wp_posts AS PO 
                    ON PM.meta_value=PO.ID  
                WHERE PM.post_id = P.ID 
                  AND PM.meta_key = '_thumbnail_id' 
              ) AS 'images',
              (
                SELECT CONCAT('["',group_concat(PO.ID separator  '","'),'"]')
                FROM wp_postmeta AS PM 
                  INNER JOIN wp_posts AS PO 
                    ON PM.meta_value=PO.ID  
                WHERE PM.post_id = P.ID 
                  AND PM.meta_key = '_thumbnail_id' 
              ) AS 'images_ids'
      FROM  wp_users A 
        INNER JOIN wp_posts P 
          ON P.post_author = A.ID
        LEFT JOIN contadorvisitas C
          ON P.ID = C.idnoticia 
      WHERE P.post_status='publish' 
        AND P.post_type='post'
        AND P.ID = NEW.ID
      ORDER BY P.post_date ASC;
    END IF;
  ELSE
    DELETE FROM bbcl_dwh WHERE ID = NEW.ID;
  END IF;
END
|
DELIMITER ;

--## TRIGGER DELETE
DELIMITER |
CREATE TRIGGER onDeletedPost AFTER DELETE ON wp_posts
FOR EACH ROW BEGIN
  DELETE FROM bbcl_dwh WHERE ID = OLD.ID;
END
|
DELIMITER ;




