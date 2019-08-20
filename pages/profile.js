import React, { Component, useRef } from 'react';
import { Header, Icon, Loader, Divider, Dimmer, Message, Segment, Button, Grid, Rating } from 'semantic-ui-react';
import Layout from '../components/Layout';
import web3 from '../ethereum/web3';
import factory from '../ethereum/factory';
import Profile from '../ethereum/profile';
import ReactToPrint from 'react-to-print';
// import Rental from '../ethereum/rental';
import { Link, Router } from '../routes';

class ProfileShow extends Component {

    state = {
        loader: this.props.loader,
        address: null,
        isUser: this.props.isUser,
        token: 10,
        numOfQues: 0,
        rateOfQues: 0,
        numOfAns: 0,
        rateOfAns: 0
    };

    async componentDidMount() {
        if(this.props.address == 'user'){
            const accounts = await web3.eth.getAccounts();
            const hasAddress = await factory.methods.hasProfile(accounts[0]).call();
            if(!hasAddress){
                this.setState({ address: accounts[0], isUser: false, loader: false });
            } else {
                const profileAddress = await factory.methods.getProfile(accounts[0]).call();
                var profile = Profile(profileAddress);
                var token = await profile.methods.getToken().call(); 
                var numOfQues = await profile.methods.getNumOfQues().call();
                var rateOfQues = await profile.methods.getavgQuesRate().call();
                var numOfAns = await profile.methods.getNumOfAns().call();   
                var rateOfAns = await profile.methods.getavgAnsRate().call();
                var loader = false;
                var isUser = true;

                this.setState({ address: accounts[0], loader , isUser, token, numOfQues, numOfAns, rateOfQues, rateOfAns });
            }
        }
    }

    static async getInitialProps(props) {
        const { address } = props.query;
        if(address == 'user'){
            var loader = true;
            var isUser = false;
        } else {
            var loader = false;
            var isUser = true;
        }

        return { address , loader, isUser };
    }

    renderUser(){
        return(
            <React.Fragment>
                <Header as='h2' icon textAlign='center' style={{marginTop: 10}}>
                    <Icon name='user' circular/>
                    <Header.Content>USER ID</Header.Content>
                    <Header.Subheader>
                        <div style={{overflow: 'hidden', textOverflow: 'ellipsis'}}>{this.state.address}</div>
                    </Header.Subheader>
                    <p>Number of Tokens: {this.state.token/1}</p>
                </Header>
                <Segment size='big'>
                    <Grid columns={2} relaxed='very'>
                        <Grid.Column textAlign='center'>
                            <p>Number of Questions: {this.state.numOfQues/1}</p>
                            Rating: 
                            <Rating icon='star' size='large' 
                                            rating={this.state.rateOfQues/1}
                                            maxRating={5} disabled />
                        </Grid.Column>
                        <Grid.Column textAlign='center'>
                            <p>Number of Answers: {this.state.numOfAns/1}</p>
                            
                            Rating: 
                            <Rating icon='star' size='large' 
                                            rating={this.state.rateOfAns/1}
                                            maxRating={5} disabled />
                        </Grid.Column>
                    </Grid>
                    <Divider vertical></Divider>
                </Segment>

            </React.Fragment>
        );
    }

    renderNonUser() {
        return(
            <React.Fragment>
                <Header as='h2' icon textAlign='center'>
                    <Icon name='user' circular />
                    <Header.Content>GUEST USER</Header.Content>
                    <Header.Subheader>
                        <div style={{overflow: 'hidden', textOverflow: 'ellipsis'}}>{this.state.address}</div>
                    </Header.Subheader>
                    <span>Number of Tokens: {this.state.token}</span>
                </Header>
            </React.Fragment>
        );
    }

    render() {
        const ownProfile = this.props.address == 'user' && this.state.address;
        const whichProfile = ownProfile ? 'Your Profile' : 'User Profile';
        return(
            <Layout>
                <h3>{whichProfile}</h3>
                {ownProfile && <Message color='green' compact style={{marginTop: 0, padding: 10}}>
                    <Icon name='check circle'/>
                    Your profile is verified
                </Message>}
               
                <div ref={el => (this.componentRef = el)}>
                    <Segment color='yellow'>
                        <Header as='h1' color='red' textAlign='center'>
                            <Icon name='certificate'/>
                            <Header.Content>Certificate</Header.Content>
                        </Header>
                    {this.state.isUser? this.renderUser() : this.renderNonUser()} 
                    </Segment>
                </div>

                <Divider hidden/>

                <Grid centered>
                    <ReactToPrint
                        trigger={() => <a href="#"><Button primary>Print</Button></a>}
                        content={() => this.componentRef}
                    />
                </Grid>
               
                <Dimmer active={this.state.loader} inverted style={{ position: 'fixed' }}>
                    <Loader size='large'>Loading</Loader>
                </Dimmer>
            </Layout>
        );
    }
}


export default ProfileShow;
