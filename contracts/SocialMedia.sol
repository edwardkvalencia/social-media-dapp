// This contract allows people to publish strings of text 
// and follow hashtags. User accounts will be anonymous, addresses
// will be the only identifiers

pragma solidity ^0.5.0;

contract SocialMedia {
    struct Content {
        uint256 id;
        address author;
        uint256 date;
        string content;
        bytes32[] hashtags;
    }

    event ContentAdded(
        uint256 indexed id, 
        address indexed author,
        uint256 indexed date, 
        string content,
        bytes32[] hashtags
    );

    mapping(address => bytes32[]) public subscribedHashtags;
    mapping(bytes32 => uint256) public hashtagScore;
    mapping(bytes32 => Content[]) public contentByHashtag;
    mapping(uint256 => Content) public contentById;
    mapping(bytes32 => bool) public doesHashtagExist;
    mapping(address => bool) public doesUserExist;
    address[] public users;
    Content[] public contents;
    bytes32[] public hashtags;
    uint256 public latestContentId;

    // to add new content. If no # are sent, content added to #general hashtag list
    function addContent(
        string memory _content, 
        bytes32[] memory _hashtags
    ) public {
        require(bytes(_content).length > 0, 'Content cannot be empty');
        
        // create Content struct instance with the required param, 
        // populating the mappings that use that struct
        Content memory newContent = Content(
            latestContentId, 
            msg.sender, 
            now, 
            _content, 
            _hashtags
        );

        //If no # specified then auto saved to #general hashtag
        if(_hashtags.length == 0) {
            contentByHashtag['general'].push(newContent);
            hashtagScore['general']++;
            if(!doesHashtagExist['general']) {
                hashtags.push('general');
                doesHashtagExist['general'] = true;
            }
        // Content added to all hashtags specified
        // Create new ones that haven't been there b4    
        } else {
            for(uint256 i = 0; i < _hashtags.length; i++) {
                contentByHashtag[_hashtags[i]].push(newContent);
                hashtagScore[_hashtags[i]]++;
                if(!doesHashtagExist[_hashtags[i]]) {
                    hashtags.push(_hashtags[i]);
                    doesHashtagExist[_hashtags[i]] = true;
                }
            }
        }
        hashtags = sortHashtagsByScore();
        contentById[latestContentId] = newContent;
        contents.push(newContent);

        //Add user to the array of users if not already
        if(!doesUserExist[msg.sender]) {
            users.push(msg.sender);
            doesUserExist[msg.sender] = true;
        }

        // emit event to notify others
        emit ContentAdded(
            latestContentId,
            msg.sender,
            now,
            _content,
            _hashtags 
        );
        latestContentId++;
    }

    // To subscribe to a hashtag
    function subscribeToHashtag(bytes32 _hashtag) public {
        if(!checkExistingSubscription(_hashtag)) {
            subscribedHashtags[msg.sender].push(_hashtag);
            hashtagScore[_hashtag]++;
            hashtags = sortHashtagsByScore();
        }
    }
    
    // To unsubscribe, if not subscribed then does nothing
    function unsubsribeToHashtag(bytes32 _hashtag) public {
        if(checkExistingSubscription(_hashtag)) {
            for(uint256 i = 0; i < subscribedHashtags[msg.sender].length; i++) {
                if(subscribedHashtags[msg.sender][i] == _hashtag) {
                    delete subscribedHashtags[msg.sender][i];
                    hashtagScore[_hashtag]--;
                    hashtags = sortHashtagsByScore();
                    break;
                }
            }
        }
    }

    // Returns indicated amount of top hashtags
    function getTopHashtags(uint256 _amount) public view returns(bytes32[] memory) {
        bytes32[] memory result;

        if(hashtags.length < _amount) {
            result = new bytes32[] (hashtags.length);
            for(uint256 i = 0; i < hashtags.length; i++) {
                result[i] = hashtags[i];
            }
        }
        return result;
    }

    // Get the followed hashtag names for this msg.sender
    function getFollowedHashtags() public view returns (bytes32[] memory) {
        return subscribedHashtags[msg.sender];
    }

    // get content for given hashtag. Returns the ids b/c we can't return arrays of strings or structs
    function getContentIdsByHashtag(bytes32 _hashtag, uint256 _amount) public view returns(uint256[] memory) {
        uint256[] memory ids = new uint256[](_amount);
        for(uint256 i = 0; i < _amount; i++) {
            ids[i] = contentByHashtag[_hashtag][i].id;
        }
        return ids;
    }

    // Returns data for a given id
    function getContentById(uint256 _id) public view returns(
        uint256, 
        address,
        uint256,
        string memory,
        bytes32[] memory
    ) {
        Content memory c = contentById[_id];
        return (c.id, c.author, c.date, c.content, c.hashtags);
    }

    // Sorts hashtags given their hashtag score. Returns sorted array
    function sortHashtagsByScore() public view returns(bytes32[] memory) {
        bytes32[] memory _hashtags = hashtags;
        bytes32[] memory sortedHashtags = new bytes32[](hashtags.length);
        uint256 lastId = 0;

        for(uint256 i = 0; i < _hashtags.length; i++) {
            for (uint256 j = i + 1; j < _hashtags.length; j++) {
                if(hashtagScore[_hashtags[i]] < hashtagScore[_hashtags[j]]) {
                    bytes32 temporaryhashtag = _hashtags[i];
                    _hashtags[i] = _hashtags[j];
                    _hashtags[j] = temporaryhashtag;
                }
            }

            sortedHashtags[lastId] = _hashtags[i];
            lastId++;
        }
        return sortedHashtags;
    }

    // Check if user is already subscribed to a hashtag
    function checkExistingSubscription(bytes32 _hashtag) public view returns(bool) {
        for(uint256 i = 0; i < subscribedHashtags[msg.sender].length; i++) {
            if(subscribedHashtags[msg.sender][i] == _hashtag) return true;
        }
        return false;
    }
}