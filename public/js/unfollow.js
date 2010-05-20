
function UnfollowEngine() {
    this.getFollowing('Getting followers');
}

UnfollowEngine.prototype = {
    state: {},
    
    ajax: function(options) {
        var self = this;
        
        $.ajax($.extend(options, {
            dataType: 'json',
            success: $.proxy(options.success, self),
            
            error: function(xhr, status, error) {
                self.setContent('<div class="error">' + this.errorMessage + '</div>', true);
                console.log('error');
                console.log(xhr);
            }
        }));
    },
    
    setContent: function(content, isStatus) {
        var container = $('#content').html(content);
        
        if(isStatus) {
            container.addClass('status');
        } else {
            container.removeClass('status');
        }
    },
    
    showLoading: function(message) {
        var content = '<div><img src="img/loading.gif" alt="loading" /></div>'
                    + '<div>' + message + '</div>';
        this.setContent(content, true);
    },
    
    showRedirect: function(url, errorMessage) {
        var linkToLogin = function(content) {
			return '<div><a href="' + url + '">' + content + '</a></div>';
		};
        
		var loginImage = linkToLogin('<img src="img/signin.png" alt="Click to sign in" />');
		var loginText = linkToLogin('You must be signed in to continue');
		this.setContent(errorMessage + loginImage + loginText, true);
    },
    
    unfollow: function() {
        var state = this.state;
        var users = [];
        
        $.each(state, function(key, value) {
            if(!value) users.push(key);
        });
        
        this.ajax({
            type: 'PUT',
            url: '/api/unfollow',
            errorMessage: 'Could not unfollow users',
            
            data: {
                users: users.join(',')
            },
            
            success: function(json) {
                this.getFollowing('Refreshing');
            }
        });
    },
    
    getFollowing: function(message) {
        this.showLoading(message);
        
        this.ajax({
            url: '/api/following',
            errorMessage: 'Could not get user data',

            success: function(json) {
                if(json.type == 'results') {
            		this.showResults(json.users);
                } else {
                    this.showRedirect(json.redirect, json.errorMessage || '');
                }
            }
        });
    },
    
    showResults: function(users) {
        var data = [];
		var self = this;
        
        $.each(users, function(index, value) {
            var linkToProfile = function(content) {
    			return '<a href="http://twitter.com/' + value.screenName + '">' + content + '</a>';
    		};
            
            var checkbox = '<input type="checkbox" checked="checked" />'
            var profileImage = linkToProfile('<img src="' + value.profileImage + '" alt="" width="48" height="48" />');
            var screenName = linkToProfile(value.screenName);
            var verified = '<img src="/img/' + value.verified + '.png" alt="' + value.verified + '" />'
            var status = value.status || '&nbsp;';
            data.push([checkbox, profileImage, screenName, verified, status]);
        });
        
        this.setContent('<div id="tableContent">', false);
        
        $('#tableContent').dataTable({
		    iDisplayLength: 100,
		    sPaginationType: 'full_numbers',
		    bFilter: true,
		    bPaginate: true,
		    bStateSave: true,
		    bJQueryUI: true,
		    bAutoWidth: true,
		    
		    aoColumns: [
		        {sTitle: 'Follow', bSortable: false},
    		    {sTitle: 'Picture', bSortable: false},
		        {sTitle: 'screen name'},
		        {sTitle: 'verified?', bSortable: false},
		        {sTitle: 'latest status', sWidth: '50%'}
		    ],
		    
		    aaData: data
		});
		
		$('#tableContent :checkbox').change(function() {
	        var screenName = $(':nth-child(3)', $(this).parent().parent()).text();
		    var checked = $(this).attr('checked');
		    self.state[screenName] = checked;
		});
		
		var button = $('<a href="#">continue &raquo;</a>').click($.proxy(function() {
		    this.unfollow();
		}, this));
		
		$('#content').append($('<div id="unfollowButton">').html(button));
    }
}

var engine = new UnfollowEngine();