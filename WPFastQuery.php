<?PHP

require_once(dirname(__FILE__)."/config.inc.php");
require_once(dirname(__FILE__)."/libraries/Database.class.php");

/*
	Autor: EstebanFuentealba
	Email: efuentealba@json.cl
*/

class WPFastQuery {
	
	protected $_db				= null;
	protected $_querySearch 	= "";
	protected $_categorySearch 	= "";
	protected $_tagSearch 		= "";
	protected $_authorSearch 	= "";
	protected $_orderBy 		= "post_date DESC";
	protected $_page			= 1;
	protected $_limit			= 10;
	protected $_default_images 	= "default-no-image";
	function __construct(){
		$this->_db = new Database(DB_SERVER, DB_USER, DB_PASS, DB_DATABASE);
	}
	
	public function find($opts = array()) {
		##	Query Search
		if(array_key_exists("q", $opts)) {
			if(isset($opts["q"])) {
				$this->_querySearch .=<<<Koala
				AND (post_title LIKE '%{$opts["q"]}%') 
Koala;
			}
		}
		## 	Categories
		if(array_key_exists("categories", $opts)) {
			if(isset($opts["categories"])) {
				if(is_numeric($opts["categories"])) {
					$this->_categorySearch .=<<<Koala
						categories_ids LIKE '%"{$opts["categories"]}"%' AND 
Koala;
				} else if(is_array($opts["categories"])) {
					$index = 0;
					foreach($opts["categories"] as $category) {
						if(is_numeric($category)) {
							$or = (($index < (count($opts["categories"])-1)) ? "OR " : "");
							$this->_categorySearch .=<<<Koala
								categories_ids LIKE '%"{$category}"%' {$or} 
Koala;
							$this->_categorySearch = "(".$this->_categorySearch.") AND ";
						} else {
							$or = (($index < (count($opts["categories"])-1)) ? "OR " : "");
							$this->_categorySearch .=<<<Koala
								categories_slugs LIKE '%"{$category}"%' {$or} 
Koala;
							$this->_categorySearch = "(".$this->_categorySearch.") AND ";
						}
						$index++;
					}
				}
			}
		}
		## 	Tags
		if(array_key_exists("tags", $opts)) {
			if(is_numeric($opts["tags"])) {
				$this->_tagSearch .=<<<Koala
					tags_ids LIKE '%"{$opts["tags"]}"%' AND 
Koala;
			} else if(is_array($opts["tags"])) {
				$index = 0;
				foreach($opts["tags"] as $tag) {
					if(is_numeric($tag)) {
						$or = (($index < (count($opts["tags"])-1)) ? "OR " : "");
						$this->_tagSearch .=<<<Koala
							tags_ids LIKE '%"{$tag}"%' {$or} 
Koala;
					} else {
						$or = (($index < (count($opts["tags"])-1)) ? "OR " : "");
						$this->_tagSearch .=<<<Koala
							tags_slugs LIKE '%"{$tag}"%' {$or} 
Koala;
					}
					$index++;
				}
				$this->_tagSearch = "(".$this->_tagSearch.") AND";
			}
		}
		
		##	Author
		if(array_key_exists("authors", $opts)) {
			
			if(is_numeric($opts["authors"])) {
				$this->_authorSearch .=<<<Koala
					post_author_id IN("{$opts["authors"]}") 
Koala;
			} else if(is_array($opts["authors"])) {
				$tmp = array();
				$index = 0;
				foreach ($opts["authors"] as $author) {
					if(is_numeric($author)) {
						$or = (($index < (count($opts["authors"])-1)) ? "OR " : "");
						$this->_authorSearch .=<<<Koala
							post_author_id = '{$author}' {$or}
Koala;
					} else {
						$or = (($index < (count($opts["authors"])-1)) ? "OR " : "");
						$this->_authorSearch .=<<<Koala
							author_name = '{$author}' {$or}
Koala;
					}
					$index++;
				}
				$this->_authorSearch = "(".$this->_authorSearch.") AND";
			}
		}
		return $this;
	}
	public function limit($limit = 10) {
		$this->_limit = $limit;
		return $this;
	}
	public function page($page = 1) {
		$this->_page = $page;
		return $this;
	}
	public function get($select = array()) {
		$this->_db->connect();
		$results = array();
		$sql = "";
		if(count($select) > 0 ) {
			$sql = "SELECT ".join(",",$select)."
					FROM  bbcl_dwh
					WHERE ".$this->_categorySearch." 1=1 AND ".$this->_tagSearch." 1=1 AND ".$this->_authorSearch." 1=1 ".$this->_querySearch."
					ORDER BY ".$this->_orderBy."
					LIMIT ".(($this->_page -1) * $this->_limit).", ".$this->_limit;
		} else {
			$sql ="SELECT *
					FROM  bbcl_dwh
					WHERE ".$this->_categorySearch." 1=1 AND ".$this->_tagSearch." 1=1 AND ".$this->_authorSearch." 1=1 " .$this->_querySearch."
					ORDER BY ".$this->_orderBy."
					LIMIT ".(($this->_page -1) * $this->_limit).", ".$this->_limit;
		}
		//echo $sql;
		$results = $this->_db->fetch_all_array($sql);
		$this->_db->close();
		$tmp = array();
		foreach($results as $result) {
			if(is_null($result["images"])) {
				$result["images"] = $this->_default_images;
			} else {
				$result["images"] = "/wp-content".current(json_decode($result["images"]));
			}
			if(in_array("tags",$select)){
				$result["tags"] = json_decode($result["tags"]);
			}
			if(in_array("tags_slugs",$select)){
				$result["tags_slugs"] = json_decode($result["tags_slugs"]);
			}
			if(in_array("tags_ids",$select)){
				$result["tags_ids"] = json_decode($result["tags_ids"]);
			}
			if(in_array("categories",$select)){
				$result["categories"] = json_decode($result["categories"]);
			}
			if(in_array("categories_slugs",$select)){
				$result["categories_slugs"] = json_decode($result["categories_slugs"]);
			}
			if(in_array("categories_ids",$select)){
				$result["categories_ids"] = json_decode($result["categories_ids"]);
			}
			$tmp[] = $result;
		}
		
		return $tmp;
	}
	public function orderby($order = array()) {
		if(count($order) > 0) {
			$this->_orderBy = implode(", ",$order);
		}
		return $this;
	}
}

?>