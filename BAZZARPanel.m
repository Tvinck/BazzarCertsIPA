#import "BAZZARPanel.h"

@interface BZRPanelController : UITableViewController
@property(nonatomic, copy) NSDictionary *configuration;
@end

static NSString *BZRText(NSDictionary *config, NSString *key, NSString *fallback) {
    id value = config[key];
    return [value isKindOfClass:NSString.class] && [value length] ? value : fallback;
}

@implementation BZRPanelController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"BAZZAR";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 90;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closePanel)];
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.view.tintColor = [UIColor colorWithRed:0.95 green:0.69 blue:0.12 alpha:1];
}
- (void)closePanel { [self dismissViewControllerAnimated:YES completion:nil]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 4; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"ВАШЕ ПРИЛОЖЕНИЕ", @"О ПРИЛОЖЕНИИ", @"УСТАНОВКА", @"РАЗРАБОТЧИК КОМПОНЕНТА"][section];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.detailTextLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        cell.textLabel.text = BZRText(self.configuration, @"appTitle", @"Приложение");
        cell.detailTextLabel.text = BZRText(self.configuration, @"subtitle", @"Информация и поддержка BAZZAR");
        cell.imageView.image = [UIImage systemImageNamed:@"waveform.circle.fill"];
    } else if (indexPath.section == 1) {
        cell.textLabel.text = BZRText(self.configuration, @"buttonTitle", @"Узнать больше о приложении");
        NSURL *url = [NSURL URLWithString:BZRText(self.configuration, @"websiteURL", @"")];
        cell.detailTextLabel.text = url.host ?: @"Адрес не настроен";
        cell.imageView.image = [UIImage systemImageNamed:@"safari"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessibilityHint = @"Открывает сайт во внешнем браузере";
    } else if (indexPath.section == 2) {
        cell.textLabel.text = BZRText(self.configuration, @"certificateTitle", @"Купить сертификат");
        cell.detailTextLabel.text = @"Посмотреть тарифы на сайте";
        cell.imageView.image = [UIImage systemImageNamed:@"checkmark.seal"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessibilityHint = @"Открывает страницу тарифов во внешнем браузере";
    } else {
        cell.textLabel.text = BZRText(self.configuration, @"developer", @"BAZZAR Certs");
        cell.detailTextLabel.text = BZRText(self.configuration, @"footer", @"Сделано с любовью.");
        cell.imageView.image = [UIImage systemImageNamed:@"heart.fill"];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1 && indexPath.section != 2) return;
    NSString *key = indexPath.section == 1 ? @"websiteURL" : @"certificateURL";
    NSURL *url = [NSURL URLWithString:BZRText(self.configuration, key, @"")];
    // Limit this initial component to the explicitly supplied destination.
    if (![url.scheme.lowercaseString isEqualToString:@"https"] ||
        ![url.host.lowercaseString isEqualToString:@"bazzar-serts.shop"] || url.user || url.password) {
        [self showError:@"Проверьте адрес сайта в настройках компонента."];
        return;
    }
    __weak BZRPanelController *weakSelf = self;
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
        if (!success) dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf showError:@"Не удалось открыть сайт. Попробуйте позже."]; });
    }];
}
- (void)showError:(NSString *)message {
    if (!self.view.window || self.presentedViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BAZZAR" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Понятно" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

void BAZZARPresentPanel(UIViewController *presenter) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!presenter.viewIfLoaded.window || presenter.presentedViewController || presenter.isBeingDismissed) return;
        NSString *path = [NSBundle.mainBundle pathForResource:@"BAZZARPanel" ofType:@"plist"];
        NSDictionary *config = path ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
        BZRPanelController *panel = [[BZRPanelController alloc] initWithStyle:UITableViewStyleInsetGrouped];
        panel.configuration = config ?: @{};
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:panel];
        navigation.modalPresentationStyle = UIModalPresentationPageSheet;
        [presenter presentViewController:navigation animated:YES completion:nil];
    });
}
