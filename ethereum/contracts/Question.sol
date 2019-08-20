pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract QuestionFactory {
    address[] private deployedQuestions;
    mapping(address => address) public users;

    function createQuestion(string category, string questionTitle, string description, uint deposit, 
                    uint maxDuration, string[] fileHashesQuestion, string[] fileNamesQuestion) public payable {
        if (users[msg.sender] == 0) {
            address profile = new Profile(msg.sender);
            users[msg.sender] = profile;
        }    
        require(deposit<Profile(users[msg.sender]).getToken());
        address newQuestion = new Question(category, questionTitle, description, deposit, maxDuration,
                                    fileHashesQuestion, fileNamesQuestion, msg.sender, users[msg.sender]);
        deployedQuestions.push(newQuestion);
        
        Question question = Question(newQuestion);
        question.transfer(msg.value);
        Profile(users[msg.sender]).updateToken(0, deposit);
        Profile(users[msg.sender]).increaseNumOfQues();
        question.postQuestion();  //Save posted time here
        
    }

    function createAnswer(address _question, string _reply, string[] _fileHashes, string[] _fileNames, int _parent) public {
        if (users[msg.sender] == 0) {
            address profile = new Profile(msg.sender);
            users[msg.sender] = profile;
        }   
        Question question = Question(_question);
        question.answer(_reply, _fileHashes, _fileNames, msg.sender, users[msg.sender], _parent);
        Profile(users[msg.sender]).increaseNumOfAns();
    }

    function ratingQuestionAt(address _question, uint _ratingQuestion) public payable{
        if (users[msg.sender] == 0) {
            address profile = new Profile(msg.sender);
            users[msg.sender] = profile;
        }

        Question question = Question(_question);
        question.transfer(msg.value);
        question.ratingQuestion(_ratingQuestion); 
        question.updateDeposite(1);
        Profile(users[msg.sender]).updateToken(0, 1);
        Profile(question.getOwnerP()).increaseSumOfQuesRate(_ratingQuestion);
    }

    function ratingAnswerAt(address _question, uint _ratingAnswer, uint _index) public payable {
        if (users[msg.sender] == 0) {
            address profile = new Profile(msg.sender);
            users[msg.sender] = profile;
        }

        Question question = Question(_question);
        question.transfer(msg.value);
        question.updateAnswerRate(_ratingAnswer, _index);
        Profile(question.getAnswererP(_index)).increaseSumOfAnsRate(_ratingAnswer);
    }


    function shareTokenAt(address _question) public payable {
        if (users[msg.sender] == 0) {
            address profile = new Profile(msg.sender);
            users[msg.sender] = profile;
        }

        Question question = Question(_question);
        question.shareToken();
    }

    function hasProfile(address _user) public returns(bool) {
        if (users[_user] == 0) {
            return false;
        } else {
            return true;
        }
    }

    function getProfile(address _user) public returns(address) {
        require(users[_user] != 0);
        return users[_user];
    }
    
    function getDeployedQuestions() public view returns(address[]) {
        return deployedQuestions;
    }
}    


contract Question {

    struct Answer {
        string replyHash;
        string[] fileHashes;
        string[] fileNames;
        address answerer;
        Profile answererP;
        uint answerTime;
        uint answerRate; 
        uint answerNumRate;
        uint answerSumRate;
        int parent;
        int id;       //Keep track parent answers
    }

    Answer[] public answerList; 
    string[] public fileHashesQuestion;
    string[] public fileNamesQuestion;
    string public questionTitle;
    string public description;
    uint public deposit;
    uint public maxDuration;
    address public owner;
    Profile public ownerP;
    uint public start;
    uint public questionRate;
    uint public numRate;
    uint public sumRate;
    bool public alreadyShareToken = false;
    uint public tokenSum;
    uint public proportion;
    uint public numPeople;
    string public category;
    int public count = 0;

    function() payable { }
    
    function Question (string _category, string _questionTitle, string _description, uint _deposit, uint _maxDuration, string[] _fileHashesQuestion, string[] _fileNamesQuestion, address _owner, address _ownerP) public {
        category = _category;
        questionTitle = _questionTitle;
        description = _description;
        deposit = _deposit;
        maxDuration = _maxDuration;
        fileHashesQuestion = _fileHashesQuestion;
        fileNamesQuestion = _fileNamesQuestion;
        owner = _owner;
        ownerP = Profile(_ownerP);
    }

    function getSummary() public view returns (
        string, string, uint, uint, address, string[], string[]
    ) {
        return(
            questionTitle,
            description,
            deposit,
            maxDuration,
            owner,
            fileHashesQuestion,
            fileNamesQuestion
        );
    }

    function getCategory() public view returns (string) {
        return category;
    }

    function getOwner() public view returns (address){
        return owner;
    }

    function getOwnerP() public view returns (Profile){
        return ownerP;
    }
    
    function getAnswererP(uint _index) public view returns (Profile){
        return answerList[_index].answererP;
    }

    function getTime() public view returns (uint, uint, uint) {
        return(
            start,
            now,
            maxDuration
        );
    }

    function ratingQuestion(uint _ratingQuestion) public {
        numRate++;
        sumRate = sumRate + _ratingQuestion;
        questionRate = sumRate/numRate;
    }

    function getRatingQuestion() public returns (uint){
        return questionRate;
    }

    function updateDeposite(uint _value) public {
        deposit = deposit + _value;
    }

    function getDeposit() public returns (uint){
        return deposit;
    }

    function isOverdue() public returns (bool) {
        uint publishingTime = now - start;
        return publishingTime > maxDuration;
    }

    function getCheckShareToken() returns(bool){
        return (!alreadyShareToken);
    }

    function getNumAnswer4() returns (bool){
        uint getNumAnswer4;
        for (uint i = 0;i < answerList.length;i++) {
            if(answerList[i].answerRate >= 4) 
                getNumAnswer4++;
            if(getNumAnswer4>0) return true; 
            else return false;
        }
    }

    function shareToken() public {
        for (uint i = 0;i < answerList.length;i++) {
            if(answerList[i].answerRate >= 4){ 
                numPeople++;
            }
        }
        proportion = deposit/numPeople;
        for (i = 0; i < answerList.length;i++) {
            if(answerList[i].answerRate >= 4){ //Only take 4 stars above into account
                answerList[i].answererP.updateToken(1, proportion);
            }
        }

        alreadyShareToken = true;
    }
    
    function postQuestion() public {
        start = now;   
    }

    function answer(string _reply, string[] _fileHashes, string[] _fileNames, address _answerer, address _answererP, int _parent) public {
        int _id;
        if (_parent == -1) {   //a parent answer
            _id = count;   
            count++;
        } else {               //a child answer
            _id = -1;
        }

        Answer memory newAnswer = Answer({
            replyHash: _reply,
            fileHashes: _fileHashes,
            fileNames: _fileNames,
            answerer: _answerer,
            answererP: Profile(_answererP),
            answerTime: now,
            answerRate: 0,
            answerNumRate: 0,
            answerSumRate: 0,
            parent: _parent,
            id: _id
        }); 
        
        answerList.push(newAnswer);
    } 


    function getAnswerList() public view returns (Answer[]) {
        return answerList;
    }

    function updateAnswerRate(uint _value, uint index) public {
        answerList[index].answerNumRate ++;
        answerList[index].answerSumRate += _value;
        answerList[index].answerRate = answerList[index].answerSumRate/answerList[index].answerNumRate;
    }

    function getAnswerRate(uint index) public view returns (uint) {
        return answerList[index].answerRate;
    }

}

contract Profile {

    uint public token = 10;
    uint public numOfQues;
    uint public sumOfQuesRate;
    uint public numOfAns;
    uint public sumOfAnsRate;
    address public user;

    function Profile (address _user) public {
        user = _user;
    }

    function increaseNumOfQues() public {
        numOfQues++;
    }

    function increaseNumOfAns() public {
        numOfAns++;
    }

    function increaseSumOfQuesRate(uint _rate) public {
        sumOfQuesRate += _rate;
    }

    function increaseSumOfAnsRate(uint _rate) public {
        sumOfAnsRate += _rate;
    }

    function getavgQuesRate() public returns (uint){
        uint avgQuesRate = sumOfQuesRate/numOfQues;
        return avgQuesRate;
    }

    function getavgAnsRate() public returns (uint){
        uint avgAnsRate = sumOfAnsRate/numOfAns;
        return avgAnsRate;
    }

    function getNumOfQues() public returns (uint){
        return numOfQues;
    }

    function getNumOfAns() public returns (uint){
        return numOfAns;
    }

    function updateToken(uint addOrSub, uint _token) public {
        if (addOrSub==1){ //1 is add
            token += (_token);
        }
        else if(addOrSub==0){ // 0 is sub
            token -= (_token);
        }
    }

    function getToken() public returns(uint){
        return token;
    }
}
