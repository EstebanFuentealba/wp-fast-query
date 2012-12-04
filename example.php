<?PHP

	set_time_limit(0);
	
	require_once(dirname(__FILE__)."/WPFastQuery.php");
	
	$query 			= isset($_GET['q']) 			? $_GET['q'] : false;
	$categories 	= isset($_GET['categories']) 	? $_GET['categories'] : false;
	$tags 			= isset($_GET['tags']) 			? $_GET['tags'] : false;
	$authors 		= isset($_GET['authors']) 		? $_GET['authors'] : false;
	$page			= isset($_GET['p']) 			? $_GET['p'] : 1;
	$limit 			= isset($_GET['limit'])			? $_GET['limit'] : 10;
	$querySearch = array();
	
	if($query) {
		$querySearch["q"] = $query;
	}
	if($categories) {
		if(!is_array($categories)) {
			$querySearch["categories"] = array($categories);
		} else {
			$querySearch["categories"] = $categories;
		}
	}
	if($authors) {
		if(!is_array($authors)) {
			$querySearch["authors"] = array($authors);
		} else {
			$querySearch["authors"] = $authors;
		}
	}
	if($tags) {
		if(!is_array($tags)) {
			$querySearch["tags"] = array($tags);
		} else {
			$querySearch["tags"] = $tags;
		}
	}
	

	## Inicializate class
	$fast = new WPFastQuery();
	##  define query and define parameters
	$results = $fast->find($querySearch)
	->orderby(array(
		"post_date DESC"
	))
	->page($page)
	->limit($limit)
	->get(array(
		"post_title", 
		"images",
		"post_date",
		"post_link",
		"categories",
		//"tags",
		"categories_slugs",
		"author_display_name"
	));

	## show results
	echo "<pre>";
	print_r($results);
	echo "</pre>";
?>