import React, { Component } from 'react';
import { Menu, Segment, Container, Icon, Header, Grid, Input, Sticky, Rail } from 'semantic-ui-react';
import { Link, Router } from '../routes';

class HeaderDesktop extends Component {
    constructor(props) { 
        super(props);
        this.state = {value:this.props.searchItem};
        this.handleChange = this.handleChange.bind(this);
        this.keyPress = this.keyPress.bind(this);
     } 
   
    handleChange(e) {
        this.setState({ value: e.target.value });
     }
  
    keyPress(e){
        if(e.keyCode == 13){
           console.log('value', e.target.value);
           //console.log(encodeURIComponent(this.state.value));
           if (this.state.value!='' && this.state.value!=undefined)
                Router.pushRoute(`/${'search+'+encodeURIComponent(this.state.value)}`);
           // put the login here
        }
    }
    render() {
        return(
            <React.Fragment>
                <Rail
                    internal
                    position="left"
                    attached
                    style={{ top: "auto", height: "auto", width: "100%" }}
                >
                    <Sticky context={this.props.contextRef}>
                        <Segment inverted vertical style={{ backgroundColor: '#1F5846' ,minHeight: 100, padding: '1em 0em 0em 0em', textAlign: 'flex-end'}}>
                            <Menu inverted style={{ backgroundColor: '#1F5846' }} stackable fixed='top' size='large'>
                                <Container>
                                    <Link route="/">
                                        <a className = "item">
                                            Home
                                        </a>
                                    </Link>

                                    <Menu.Menu position ="right">
                                        <Link route="/questions/lend">
                                            <a className = "item">
                                                Post a question
                                            </a>
                                        </Link>

                                        <Link route="/profile/user">
                                            <a className = "item">
                                                Profile
                                            </a>
                                        </Link>
                                    </Menu.Menu>
                                </Container>
                            </Menu>
                            <Container style={{marginTop: '40px'}}>
                                <Grid inverted style={{padding: '0em 1em'}} relaxed verticalAlign='bottom'>
                                    <Grid.Column width={4}>
                                        <Header as='h3' inverted>
                                            <Icon name='ethereum' style={{float: 'left'}}/>EtherLearn
                                        </Header>
                                    </Grid.Column >
                                    <Grid.Column width={7} textAlign='center'>
                                        <Input icon={<Icon name='search' inverted circular link  onClick={() =>
                                    {
                                         //console.log('value ',this.state.value);
                                         if (this.state.value!='') Router.pushRoute(`/${'search+'+encodeURIComponent(this.state.value)}`);
                                        }}/>}
                                        size='small'
                                        onKeyDown={this.keyPress} 
                                        onChange={this.handleChange}
                                        value ={this.state.value}  
                                        placeholder='Search topics...' size='small' fluid/>
                                    </Grid.Column>
                                </Grid>
                            </Container>
                        </Segment>
                    </Sticky>
                </Rail>
                {this.props.children}
            </React.Fragment>
        );
    }
}

export default HeaderDesktop;

